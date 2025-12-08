function improved_checkpoint_selection()
    % STAGE 1: Filter exploitation phase (high reward)
    % STAGE 2: Filter high fairness + high throughput
    % STAGE 3: Final evaluation with optimal weights
    
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    checkpoint_dir = fullfile(base_dir, 'output', 'checkpoints');
    
    fprintf('\n=== Improved Checkpoint Selection ===\n\n');
    
    % Load all checkpoints
    checkpoint_files = dir(fullfile(checkpoint_dir, 'checkpoint_*.mat'));
    episodes = [];
    rewards = [];
    fairness = [];
    throughput = [];
    handovers = [];
    
    for i = 1:length(checkpoint_files)
        load(fullfile(checkpoint_dir, checkpoint_files(i).name));
        episodes(i) = checkpoint_data.episode;
        rewards(i) = checkpoint_data.episode_reward;
        fairness(i) = checkpoint_data.fairness;
        throughput(i) = checkpoint_data.throughput;
        handovers(i) = checkpoint_data.handovers;
    end
    
    % STAGE 1: Filter exploitation phase (last 4000 episodes)
    exploitation_mask = episodes >= 6000;
    stage1_episodes = episodes(exploitation_mask);
    stage1_rewards = rewards(exploitation_mask);
    stage1_fairness = fairness(exploitation_mask);
    stage1_throughput = throughput(exploitation_mask);
    stage1_handovers = handovers(exploitation_mask);
    
    fprintf('Stage 1: Filtered to %d exploitation-phase checkpoints (ep >= 6000)\n', ...
        sum(exploitation_mask));
    
    % STAGE 2: Filter high fairness (>0.93) AND high throughput (>10 Mbps)
    high_fairness_mask = stage1_fairness > 0.93;
    high_throughput_mask = stage1_throughput > 10.0;
    stage2_mask = high_fairness_mask & high_throughput_mask;
    
    stage2_episodes = stage1_episodes(stage2_mask);
    stage2_rewards = stage1_rewards(stage2_mask);
    stage2_fairness = stage1_fairness(stage2_mask);
    stage2_throughput = stage1_throughput(stage2_mask);
    stage2_handovers = stage1_handovers(stage2_mask);
    
    fprintf('Stage 2: Filtered to %d high-performance checkpoints (F>0.93, TP>10)\n', ...
        sum(stage2_mask));
    
    if sum(stage2_mask) < 5
        fprintf('⚠ Warning: Too few candidates. Relaxing criteria...\n');
        high_fairness_mask = stage1_fairness > 0.90;
        high_throughput_mask = stage1_throughput > 9.0;
        stage2_mask = high_fairness_mask & high_throughput_mask;
        
        stage2_episodes = stage1_episodes(stage2_mask);
        stage2_fairness = stage1_fairness(stage2_mask);
        stage2_throughput = stage1_throughput(stage2_mask);
        stage2_handovers = stage1_handovers(stage2_mask);
        
        fprintf('  Relaxed to %d candidates (F>0.90, TP>9.0)\n', sum(stage2_mask));
    end
    
    % Display Stage 2 candidates
    fprintf('\nStage 2 Candidates:\n');
    fprintf('%-10s %-12s %-15s %-12s\n', 'Episode', 'Fairness', 'Throughput', 'Handovers');
    fprintf('%-10s %-12s %-15s %-12s\n', '-------', '--------', '----------', '---------');
    for i = 1:length(stage2_episodes)
        fprintf('%-10d %-12.4f %-15.2f %-12d\n', ...
            stage2_episodes(i), stage2_fairness(i), ...
            stage2_throughput(i), stage2_handovers(i));
    end
    
    % STAGE 3: Find optimal weights with constrained search
    fprintf('\nStage 3: Finding optimal weights (all metrics >= 15%%)...\n');
    optimal_weights = find_optimal_weights_constrained(stage2_episodes, ...
        stage2_fairness, stage2_throughput, stage2_handovers);
    
    fprintf('Optimal Weights:\n');
    fprintf('  Fairness:   %.2f\n', optimal_weights.x);
    fprintf('  Throughput: %.2f\n', optimal_weights.y);
    fprintf('  Handovers:  %.2f\n', optimal_weights.z);
    
    % Calculate final scores
    norm_fairness = (stage2_fairness - min(stage2_fairness)) / ...
        (max(stage2_fairness) - min(stage2_fairness) + eps);
    norm_throughput = (stage2_throughput - min(stage2_throughput)) / ...
        (max(stage2_throughput) - min(stage2_throughput) + eps);
    norm_handovers = (max(stage2_handovers) - stage2_handovers) / ...
        (max(stage2_handovers) - min(stage2_handovers) + eps);
    
    final_scores = optimal_weights.x * norm_fairness + ...
                   optimal_weights.y * norm_throughput + ...
                   optimal_weights.z * norm_handovers;
    
    [~, sorted_idx] = sort(final_scores, 'descend');
    top_k = min(10, length(sorted_idx));
    
    fprintf('\nTop %d Checkpoints (Weighted Score):\n', top_k);
    fprintf('%-6s %-10s %-10s %-12s %-12s %-10s\n', ...
        'Rank', 'Episode', 'Score', 'Fairness', 'Throughput', 'Handovers');
    fprintf('%-6s %-10s %-10s %-12s %-12s %-10s\n', ...
        '----', '-------', '-----', '--------', '----------', '---------');
    
    for i = 1:top_k
        idx = sorted_idx(i);
        fprintf('%-6d %-10d %-10.4f %-12.4f %-12.2f %-10d\n', ...
            i, stage2_episodes(idx), final_scores(idx), ...
            stage2_fairness(idx), stage2_throughput(idx), stage2_handovers(idx));
    end
    
    % STAGE 4: Evaluate top candidate with 50 runs
    best_episode = stage2_episodes(sorted_idx(1));
    fprintf('\n=== Final Evaluation: Episode %d (50 runs) ===\n', best_episode);
    
    checkpoint_file = fullfile(checkpoint_dir, sprintf('checkpoint_%05d.mat', best_episode));
    load(checkpoint_file);
    
    % Recreate agent
    config = struct('learning_rate', 0.01, 'gamma', 0.97, ...
        'epsilon_start', 0.05, 'epsilon_decay', 1, 'epsilon_min', 0.05, ...
        'num_actions', 8, 'state_dim', 4, 'bins_per_dim', 4);
    agent = QLearningAgent(config);
    agent.Q_table = checkpoint_data.Q_table;
    agent.epsilon = checkpoint_data.epsilon;
    
    % Run 50 evaluations
    eval_fairness = zeros(1, 50);
    eval_throughput = zeros(1, 50);
    eval_handovers = zeros(1, 50);
    
    for run = 1:50
        fprintf('  Eval run %d/50...\n', run);
        res = rl_enhanced_simulation(agent, 1, true);
        eval_fairness(run) = mean((res.fairness + res.fairness_ul) / 2);
        eval_throughput(run) = mean((res.avg_allocation + res.avg_allocation_ul) / 2);
        eval_handovers(run) = sum(res.handovers);
    end
    
    fprintf('\n=== Final Results (50-run average) ===\n');
    fprintf('Fairness:   %.4f ± %.4f\n', mean(eval_fairness), std(eval_fairness));
    fprintf('Throughput: %.2f ± %.2f Mbps\n', mean(eval_throughput), std(eval_throughput));
    fprintf('Handovers:  %.1f ± %.1f\n', mean(eval_handovers), std(eval_handovers));
    
    % Save best agent
    agent.save(fullfile(base_dir, 'output', 'data', 'trained_agent_improved.mat'));
    fprintf('\n✓ Saved improved agent to: output/data/trained_agent_improved.mat\n');
end

function optimal = find_optimal_weights_constrained(episodes, fairness, throughput, handovers)
    % Constrained grid search: all weights >= 0.15
    step = 0.05;
    vals = 0.15:step:0.70;
    
    best_score = -inf;
    best_weights = [0.33, 0.33, 0.34];
    
    for x = vals
        for y = vals
            z = 1 - x - y;
            if z >= 0.15 && z <= 0.70
                % Normalize metrics
                norm_f = (fairness - min(fairness)) / (max(fairness) - min(fairness) + eps);
                norm_t = (throughput - min(throughput)) / (max(throughput) - min(throughput) + eps);
                norm_h = (max(handovers) - handovers) / (max(handovers) - min(handovers) + eps);
                
                scores = x * norm_f + y * norm_t + z * norm_h;
                mean_score = mean(scores);
                
                if mean_score > best_score
                    best_score = mean_score;
                    best_weights = [x, y, z];
                end
            end
        end
    end
    
    optimal = struct('x', best_weights(1), 'y', best_weights(2), 'z', best_weights(3));
end
