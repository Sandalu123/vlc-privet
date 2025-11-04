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
    
    fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║              Checkpoint Selection Process                    ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    checkpoint_files = dir(fullfile(checkpoint_dir, 'checkpoint_ep*.mat'));
    fprintf('Loading %d checkpoints...\n', length(checkpoint_files));
    
    checkpoints = [];
    for i = 1:length(checkpoint_files)
        cp_data = load(fullfile(checkpoint_dir, checkpoint_files(i).name));
        checkpoints(i).episode = cp_data.episode;
        checkpoints(i).fairness = cp_data.fairness;
        checkpoints(i).throughput = cp_data.throughput;
        checkpoints(i).handovers = cp_data.handovers;
        checkpoints(i).filename = checkpoint_files(i).name;
    end
    
    [~, idx] = sort([checkpoints.fairness], 'descend');
    top_fairness = checkpoints(idx(1:min(20, length(idx))));
    fprintf('Step 1: Selected top 20 by fairness\n');
    
    filtered = top_fairness([top_fairness.fairness] >= 0.92);
    fprintf('Step 2: Filtered checkpoints with fairness >= 0.92 (%d remaining)\n', length(filtered));
    
    if isempty(filtered)
        fprintf('\n⚠ No suitable checkpoints found. Using best fairness checkpoint.\n');
        selected_checkpoint = top_fairness(1);
    else
        [~, idx] = sort([filtered.throughput], 'descend');
        top_10_candidates = filtered(idx(1:min(10, length(idx))));
        fprintf('Step 3: Selected top 10 by throughput\n');
        fprintf('Step 4: Evaluating candidates (3 runs each)...\n\n');
        
        top_10 = [];
        for i = 1:length(top_10_candidates)
            cp_data = load(fullfile(checkpoint_dir, top_10_candidates(i).filename));
            temp_agent = QLearningAgent(struct(...
                'learning_rate', 0.01, ...
                'gamma', 0.97, ...
                'epsilon_start', 0.05, ...
                'epsilon_decay', 1, ...
                'epsilon_min', 0.05, ...
                'num_actions', length(actions), ...
                'state_dim', 4, ...
                'bins_per_dim', 4));
            temp_agent.Q_table = cp_data.Q_table;
            temp_agent.epsilon = cp_data.epsilon;
            
            eval_results = rl_enhanced_simulation(temp_agent, 3);
            
            fairness_vals = [];
            throughput_vals = [];
            handover_vals = [];
            for j = 1:length(eval_results)
                fairness_vals(j) = mean(eval_results{j}.fairness);
                throughput_vals(j) = mean(eval_results{j}.avg_allocation);
                handover_vals(j) = sum(eval_results{j}.handovers);
            end
            
            top_10(i).episode = top_10_candidates(i).episode;
            top_10(i).fairness = mean(fairness_vals);
            top_10(i).throughput = mean(throughput_vals);
            top_10(i).handovers = mean(handover_vals);
            top_10(i).filename = top_10_candidates(i).filename;
            
            fprintf('  Evaluated Ep %d: Fair=%.3f Tput=%.2f HO=%.1f\n', ...
                top_10(i).episode, top_10(i).fairness, top_10(i).throughput, top_10(i).handovers);
        end
        fprintf('\n');
        
        fprintf('╔════════════════════════════════════════════════════════════════════╗\n');
        fprintf('║                    Top 10 Checkpoints                              ║\n');
        fprintf('╠════╦═════════╦═══════════╦═════════════╦════════════════════════╣\n');
        fprintf('║ #  ║ Episode ║ Fairness  ║ Throughput  ║ Handovers              ║\n');
        fprintf('╠════╬═════════╬═══════════╬═════════════╬════════════════════════╣\n');
        
        for i = 1:length(top_10)
            fprintf('║ %-2d ║ %-7d ║   %.4f  ║  %.2f Mbps  ║       %2d               ║\n', ...
                i, top_10(i).episode, top_10(i).fairness, ...
                top_10(i).throughput, top_10(i).handovers);
        end
        fprintf('╚════╩═════════╩═══════════╩═════════════╩════════════════════════╝\n\n');
        
        selection = input('Select checkpoint (1-10): ');
        while selection < 1 || selection > length(top_10)
            fprintf('Invalid selection. Please enter a number between 1 and %d\n', length(top_10));
            selection = input('Select checkpoint (1-10): ');
        end
        
        selected_checkpoint = top_10(selection);
    end
    
    fprintf('\n--- Loading Selected Checkpoint ---\n');
    cp_data = load(fullfile(checkpoint_dir, selected_checkpoint.filename));
    agent.Q_table = cp_data.Q_table;
    agent.epsilon = cp_data.epsilon;
    
    fprintf('✓ Checkpoint loaded: Episode %d\n', selected_checkpoint.episode);
    fprintf('  Fairness:   %.4f\n', selected_checkpoint.fairness);
    fprintf('  Throughput: %.2f Mbps\n', selected_checkpoint.throughput);
    fprintf('  Handovers:  %d\n', selected_checkpoint.handovers);
    
    training_stats.selected_checkpoint = selected_checkpoint;
    
    agent.save(fullfile(output_dir, 'trained_agent.mat'));
    save(fullfile(output_dir, 'training_stats.mat'), 'training_stats');
    
    fprintf('\nTraining complete!\n');
end
