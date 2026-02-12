function compare_all_methods(num_runs)
    if nargin < 1
        num_runs = 30;
    end
    
    fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║         Comparing All Allocation Methods                     ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    
    addpath(fullfile(base_dir, 'config'));
    addpath(fullfile(base_dir, 'simulation'));
    addpath(fullfile(base_dir, 'algorithms', 'allocation'));
    addpath(fullfile(base_dir, 'algorithms', 'rl'));
    
    wwa_results = run_baseline_experiments('wwa', num_runs);
    fprintf('✓ WWA baseline completed\n');
    
    % Proportional baseline removed
    
    agent_path = fullfile(base_dir, 'output', 'data', 'trained_agent.mat');
    if isfile(agent_path)
        % Initialize a default agent first
        temp_config = struct('learning_rate', 0.01, 'gamma', 0.97, 'epsilon_start', 0.05, ...
                           'epsilon_decay', 1, 'epsilon_min', 0.05, 'num_actions', 8, ...
                           'state_dim', 4, 'bins_per_dim', 4);
        agent = QLearningAgent(temp_config);
        
        % Load parameters from file
        agent.load(agent_path);
        
        rl_results = run_rl_experiments(agent, num_runs);
        fprintf('✓ RL-enhanced completed\n');
    else
        fprintf('⚠ No trained agent found. Skipping RL comparison.\n');
        rl_results = [];
    end
    
    comparison = struct();
    comparison.wwa = wwa_results;
    comparison.rl = rl_results;
    
    output_dir = fullfile(base_dir, 'output', 'data');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    save(fullfile(output_dir, 'comparison_results.mat'), 'comparison');
    
    create_comparison_plots(comparison);
    generate_comparison_report(comparison);
    
    fprintf('\n✓ Comparison complete!\n');
    fprintf('  Results saved to: output/data/comparison_results.mat\n');
    fprintf('  Plots saved to: output/plots/\n');
    fprintf('  Report saved to: output/reports/\n\n');
end

function results = run_baseline_experiments(method, num_runs)
    results = struct();
    results.fairness = zeros(1, num_runs);
    results.throughput = zeros(1, num_runs);
    results.handovers = zeros(1, num_runs);
    
    for run = 1:num_runs
        res = baseline_simulation(method, 1, true);  % Suppress plots
        results.fairness(run) = mean((res.fairness + res.fairness_ul) / 2);
        results.throughput(run) = mean((res.avg_allocation + res.avg_allocation_ul) / 2);
        results.handovers(run) = sum(res.handovers);
    end
    
    % Generate single final plot
    fprintf('\nGenerating final WWA baseline plot...\n');
    baseline_simulation(method, 1, false);  % Show plot
end

function results = run_rl_experiments(agent, num_runs)
    results = struct();
    results.fairness = zeros(1, num_runs);
    results.throughput = zeros(1, num_runs);
    results.handovers = zeros(1, num_runs);
    
    for run = 1:num_runs
        fprintf('  Run %d/%d... ', run, num_runs);
        res = rl_enhanced_simulation(agent, 1, true);  % Suppress plots during multi-run
        fprintf('Done\n');
        results.fairness(run) = mean((res.fairness + res.fairness_ul) / 2);
        results.throughput(run) = mean((res.avg_allocation + res.avg_allocation_ul) / 2);
        results.handovers(run) = sum(res.handovers);
    end
    
    % Generate single final plot after all runs
    fprintf('\nGenerating final RL plots...\n');
    rl_enhanced_simulation(agent, 1, false);  % Show plots for final run
end
