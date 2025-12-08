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
    
    % Use config from arguments
    % config.num_episodes = 10000; % Removed override
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
    
    % Create exactly 20 checkpoints
    checkpoint_interval = floor(num_episodes / 20);
    
    for episode = 1:num_episodes
        base_params = load_config();
        episode_reward = 0;
        
        network = create_network(base_params);
        results = initialize_results(base_params);
        
        prev_state = [];
        prev_action = [];
        
        for t = 1:base_params.simulation_time
            if t == 1
                users = create_hybrid_users(base_params, network, t);
            else
                users = update_user_movement(users, base_params, network, t);
            end
            
            state = extract_state(users, network, results, t);
            action_idx = agent.select_action(state);
            params = apply_rl_action(action_idx, actions, base_params);
            
            [users, handover_count] = perform_handover(users, network, params);
            [wifi_users, vlc_users] = split_users_by_network(users);
            
            % Downlink Allocation
            wifi_alloc = allocate_resources(wifi_users, params.wifi_capacity, params.allocation_method, 'downlink');
            vlc_alloc = allocate_resources(vlc_users, params.vlc_capacity, params.allocation_method, 'downlink');
            
            % Uplink Allocation
            wifi_alloc_ul = allocate_resources(wifi_users, params.wifi_capacity_ul, params.allocation_method, 'uplink');
            vlc_alloc_ul = allocate_resources(vlc_users, params.vlc_capacity_ul, params.allocation_method, 'uplink');
            
            users = merge_allocations(users, wifi_users, vlc_users, wifi_alloc, vlc_alloc, wifi_alloc_ul, vlc_alloc_ul);
            
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
        
        episode_reward = max(-10000, min(20000, episode_reward));
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
                episode, num_episodes, training_stats.episode_rewards(episode)/base_params.simulation_time, ...
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
    
    % Calculate statistics from exploitation phase (last 2000-3000 episodes)
    if num_episodes > 3000
        stats_start_idx = num_episodes - 3000 + 1;
    else
        stats_start_idx = floor(num_episodes * 0.7) + 1;
    end
    
    stats_range = stats_start_idx:num_episodes;
    
    % Extract data for weight calculation
    fairness_data = training_stats.episode_fairness(stats_range);
    throughput_data = training_stats.episode_throughput(stats_range);
    handovers_data = training_stats.episode_handovers(stats_range);
    
    % Calculate Optimal Weights
    [weights, norm_params] = find_optimal_weights(fairness_data, throughput_data, handovers_data);

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
    
    % Calculate composite score using Dynamic Weights
    % Score = x * norm_f + y * norm_t + z * (1 - norm_h)
    for i = 1:length(checkpoints)
        % Normalize
        n_f = (checkpoints(i).fairness - norm_params.min_f) / (norm_params.max_f - norm_params.min_f);
        n_t = (checkpoints(i).throughput - norm_params.min_t) / (norm_params.max_t - norm_params.min_t);
        n_h = (checkpoints(i).handovers - norm_params.min_h) / (norm_params.max_h - norm_params.min_h);
        
        % Clamp to [0, 1] (in case checkpoint is outside training range)
        n_f = max(0, min(1, n_f));
        n_t = max(0, min(1, n_t));
        n_h = max(0, min(1, n_h));
        
        checkpoints(i).score = weights.x * n_f + weights.y * n_t + weights.z * (1 - n_h);
    end
    
    [~, idx] = sort([checkpoints.score], 'descend');
    top_candidates = checkpoints(idx(1:min(20, length(idx))));
    
    fprintf('Step 1: Calculated scores using Dynamic Weights\n');
    fprintf('Step 2: Selected top %d candidates\n', length(top_candidates));
    fprintf('Step 3: Evaluating candidates (10 runs each) to recalculate scores...\n\n');
    
    evaluated_candidates = [];
    for i = 1:length(top_candidates)
        cp_data = load(fullfile(checkpoint_dir, top_candidates(i).filename));
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
        
        % Increased evaluation runs for stability
        eval_results = rl_enhanced_simulation(temp_agent, 50);
        
        fairness_vals = [];
        throughput_vals = [];
        handover_vals = [];
        for j = 1:length(eval_results)
            fairness_vals(j) = mean(eval_results{j}.fairness);
            throughput_vals(j) = mean(eval_results{j}.avg_allocation);
            handover_vals(j) = sum(eval_results{j}.handovers);
        end
        
        evaluated_candidates(i).episode = top_candidates(i).episode;
        evaluated_candidates(i).fairness = mean(fairness_vals);
        evaluated_candidates(i).throughput = mean(throughput_vals);
        evaluated_candidates(i).handovers = mean(handover_vals);
        evaluated_candidates(i).filename = top_candidates(i).filename;
        
        % Recalculate Score using same weights and normalization
        n_f = (evaluated_candidates(i).fairness - norm_params.min_f) / (norm_params.max_f - norm_params.min_f);
        n_t = (evaluated_candidates(i).throughput - norm_params.min_t) / (norm_params.max_t - norm_params.min_t);
        n_h = (evaluated_candidates(i).handovers - norm_params.min_h) / (norm_params.max_h - norm_params.min_h);
        
        n_f = max(0, min(1, n_f));
        n_t = max(0, min(1, n_t));
        n_h = max(0, min(1, n_h));
        
        evaluated_candidates(i).score = weights.x * n_f + weights.y * n_t + weights.z * (1 - n_h);
        
        fprintf('  Evaluated Ep %d: Fair=%.3f Tput=%.2f HO=%.1f Score=%.4f\n', ...
            evaluated_candidates(i).episode, evaluated_candidates(i).fairness, ...
            evaluated_candidates(i).throughput, evaluated_candidates(i).handovers, ...
            evaluated_candidates(i).score);
    end
    fprintf('\n');
    
    % Sort again by new score
    [~, idx] = sort([evaluated_candidates.score], 'descend');
    evaluated_candidates = evaluated_candidates(idx);

    fprintf('╔════════════════════════════════════════════════════════════════════╗\n');
    fprintf('║                    Top %d Checkpoints (Evaluated)                  ║\n', length(evaluated_candidates));
    fprintf('╠════╦═════════╦═══════════╦═════════════╦════════════════════════╦═══════════╣\n');
    fprintf('║ #  ║ Episode ║ Fairness  ║ Throughput  ║ Handovers              ║ Score     ║\n');
    fprintf('╠════╬═════════╬═══════════╬═════════════╬════════════════════════╬═══════════╣\n');
    
    for i = 1:length(evaluated_candidates)
        fprintf('║ %-2d ║ %-7d ║   %.4f  ║  %.2f Mbps  ║       %2d               ║   %.4f  ║\n', ...
            i, evaluated_candidates(i).episode, evaluated_candidates(i).fairness, ...
            evaluated_candidates(i).throughput, round(evaluated_candidates(i).handovers), ...
            evaluated_candidates(i).score);
    end
    fprintf('╚════╩═════════╩═══════════╩═════════════╩════════════════════════╩═══════════╝\n\n');
    
    selection = input(sprintf('Select checkpoint (1-%d): ', length(evaluated_candidates)));
    while selection < 1 || selection > length(evaluated_candidates)
        fprintf('Invalid selection.\n');
        selection = input(sprintf('Select checkpoint (1-%d): ', length(evaluated_candidates)));
    end
    
    selected_checkpoint = evaluated_candidates(selection);
    
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
    
    % Custom Checkpoint Saving
    save_custom = input('Do you want to replace the Custom Best Model with this checkpoint? (y/n): ', 's');
    if strcmpi(save_custom, 'y')
        custom_dir = fullfile(base_dir, 'output', 'custom_checkpoint');
        if ~exist(custom_dir, 'dir')
            mkdir(custom_dir);
        end
        agent.save(fullfile(custom_dir, 'best_model.mat'));
        fprintf('✓ Saved to: %s\n', fullfile(custom_dir, 'best_model.mat'));
    end
    
    fprintf('\nTraining complete!\n');
end
