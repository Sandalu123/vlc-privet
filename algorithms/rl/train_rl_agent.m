function [agent, training_stats] = train_rl_agent(config)
    current_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(fileparts(current_dir));
    
    addpath(fullfile(base_dir, 'config'));
    addpath(fullfile(base_dir, 'core', 'network'));
    addpath(fullfile(base_dir, 'core', 'users'));
    addpath(fullfile(base_dir, 'core', 'utils'));
    addpath(fullfile(base_dir, 'algorithms', 'allocation'));
    addpath(fullfile(base_dir, 'simulation'));
    
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
    
    % Load config but override for training
    config.num_episodes = 10000;
    config.epsilon_decay = 0.9995; % Slower decay for more exploration
    
    num_episodes = config.num_episodes;
    
    training_stats = struct();
    training_stats.episode_rewards = zeros(1, num_episodes);
    training_stats.episode_fairness = zeros(1, num_episodes);
    training_stats.episode_handovers = zeros(1, num_episodes);
    training_stats.epsilon_history = zeros(1, num_episodes);
    training_stats.q_coverage = zeros(1, num_episodes);
    training_stats.episode_throughput = zeros(1, num_episodes);
    
    checkpoint_dir = fullfile(base_dir, 'output', 'checkpoints');
    if exist(checkpoint_dir, 'dir')
        rmdir(checkpoint_dir, 's');
    end
    mkdir(checkpoint_dir);
    
    checkpoint_interval = 50;
    
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
        
        if mod(episode, checkpoint_interval) == 0 || episode == num_episodes
            checkpoint = struct();
            checkpoint.episode = episode;
            checkpoint.Q_table = agent.Q_table;
            checkpoint.epsilon = agent.epsilon;
            checkpoint.fairness = mean(results.fairness);
            checkpoint.throughput = mean(results.avg_allocation);
            checkpoint.handovers = sum(results.handovers);
            
            checkpoint_file = fullfile(checkpoint_dir, sprintf('checkpoint_ep%05d.mat', episode));
            save(checkpoint_file, '-struct', 'checkpoint');
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
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    fprintf('\n--- Saving Final Agent State ---\n');
    training_stats.selected_checkpoint = struct(...
        'episode', num_episodes, ...
        'fairness', mean(results.fairness), ...
        'throughput', mean(results.avg_allocation), ...
        'handovers', sum(results.handovers));
    
    agent.save(fullfile(output_dir, 'trained_agent.mat'));
    save(fullfile(output_dir, 'training_stats.mat'), 'training_stats');
    
    fprintf('\nTraining complete!\n');
end
