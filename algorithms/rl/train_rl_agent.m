function [agent, training_stats] = train_rl_agent(config)
    current_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(fileparts(current_dir));
    
    addpath(fullfile(base_dir, 'config'));
    addpath(fullfile(base_dir, 'core', 'network'));
    addpath(fullfile(base_dir, 'core', 'users'));
    addpath(fullfile(base_dir, 'core', 'utils'));
    addpath(fullfile(base_dir, 'algorithms', 'allocation'));
    
    actions = define_action_space_reduced();
    num_actions = length(actions);
    
    agent = QLearningAgent(struct(...
        'learning_rate', config.learning_rate, ...
        'gamma', config.gamma, ...
        'epsilon_start', config.epsilon_start, ...
        'epsilon_decay', config.epsilon_decay, ...
        'epsilon_min', config.epsilon_min, ...
        'num_actions', num_actions, ...
        'state_dim', 4, ...
        'bins_per_dim', 4));
    
    num_episodes = config.num_episodes;
    
    training_stats = struct();
    training_stats.episode_rewards = zeros(1, num_episodes);
    training_stats.episode_fairness = zeros(1, num_episodes);
    training_stats.episode_handovers = zeros(1, num_episodes);
    training_stats.epsilon_history = zeros(1, num_episodes);
    training_stats.q_coverage = zeros(1, num_episodes);
    training_stats.episode_throughput = zeros(1, num_episodes);
    
    best_score = -inf;
    best_checkpoint = [];
    checkpoint_interval = 100;
    
    for episode = 1:num_episodes
        base_params = load_config();
        episode_reward = 0;
        
        network = create_network(base_params);
        results = initialize_results(base_params);
        
        prev_state = [];
        prev_action = [];
        
        for t = 1:base_params.simulation_time
            if t == 1
                users = generate_hybrid_users(base_params, network, t);
            else
                users = update_user_movement(users, base_params, network);
            end
            
            state = extract_state(users, network, results, t);
            action_idx = agent.select_action(state);
            params = apply_rl_action(action_idx, actions, base_params);
            
            [users, handover_count] = perform_handover(users, network, params);
            [wifi_users, vlc_users] = split_users_by_network(users);
            wifi_alloc = allocate_resources(wifi_users, params.wifi_capacity, params.allocation_method);
            vlc_alloc = allocate_resources(vlc_users, params.vlc_capacity, params.allocation_method);
            users = merge_allocations(users, wifi_users, vlc_users, wifi_alloc, vlc_alloc);
            
            results = record_results(results, t, users, handover_count, params);
            
            reward = calculate_reward(results, t);
            episode_reward = episode_reward + reward;
            
            if ~isempty(prev_state)
                agent.update(prev_state, prev_action, reward, state);
            end
            
            prev_state = state;
            prev_action = action_idx;
        end
        
        agent.decay_epsilon();
        
        training_stats.episode_rewards(episode) = episode_reward;
        training_stats.episode_fairness(episode) = mean(results.fairness);
        training_stats.episode_throughput(episode) = mean(results.avg_allocation);
        training_stats.episode_handovers(episode) = sum(results.handovers);
        training_stats.epsilon_history(episode) = agent.epsilon;
        training_stats.q_coverage(episode) = agent.get_coverage();
        
        if mod(episode, checkpoint_interval) == 0 && episode >= 500
            fairness_score = mean(results.fairness);
            throughput_score = mean(results.avg_allocation) / 7.14;
            handover_score = 1 - (sum(results.handovers) / (results.total_users(1) * 0.5));
            handover_score = max(0, min(1, handover_score));
            
            composite_score = (fairness_score * 0.35) + (throughput_score * 0.40) + (handover_score * 0.25);
            
            if composite_score > best_score
                best_score = composite_score;
                best_checkpoint = struct();
                best_checkpoint.episode = episode;
                best_checkpoint.Q_table = agent.Q_table;
                best_checkpoint.epsilon = agent.epsilon;
                best_checkpoint.fairness = fairness_score;
                best_checkpoint.throughput = mean(results.avg_allocation);
                best_checkpoint.handovers = sum(results.handovers);
                best_checkpoint.score = composite_score;
                
                checkpoint_dir = fullfile(base_dir, 'output', 'checkpoints');
                if ~exist(checkpoint_dir, 'dir')
                    mkdir(checkpoint_dir);
                end
                checkpoint_file = fullfile(checkpoint_dir, sprintf('checkpoint_ep%d.mat', episode));
                save(checkpoint_file, '-struct', 'best_checkpoint');
                
                fprintf('  >> CHECKPOINT SAVED at Ep %d | Score=%.4f Fair=%.3f Tput=%.2f HO=%d\n', ...
                    episode, composite_score, fairness_score, ...
                    mean(results.avg_allocation), sum(results.handovers));
            end
        end
        
        if mod(episode, 50) == 0
            fprintf('Ep %d/%d: Rew=%.2f Fair=%.3f Tput=%.2f HO=%d Eps=%.3f Cov=%.2f%%\n', ...
                episode, num_episodes, episode_reward, ...
                mean(results.fairness), mean(results.avg_allocation), ...
                sum(results.handovers), agent.epsilon, ...
                training_stats.q_coverage(episode));
        end
    end
    
    output_dir = fullfile(base_dir, 'output', 'data');
    
    if ~isempty(best_checkpoint)
        agent.Q_table = best_checkpoint.Q_table;
        agent.epsilon = best_checkpoint.epsilon;
        
        fprintf('\n✓ Best checkpoint loaded from Episode %d\n', best_checkpoint.episode);
        fprintf('  Composite Score: %.4f\n', best_checkpoint.score);
        fprintf('  Fairness:   %.3f\n', best_checkpoint.fairness);
        fprintf('  Throughput: %.2f Mbps\n', best_checkpoint.throughput);
        fprintf('  Handovers:  %d\n', best_checkpoint.handovers);
        
        training_stats.best_checkpoint = best_checkpoint;
    else
        fprintf('\n⚠ No checkpoint saved (training may be too short)\n');
    end
    
    agent.save(fullfile(output_dir, 'trained_agent.mat'));
    save(fullfile(output_dir, 'training_stats.mat'), 'training_stats');
    
    fprintf('\nTraining complete!\n');
end
