function experiment_proportional_only()
    fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║        Experiment: Proportional Algorithm Only               ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    
    addpath(fullfile(base_dir, 'config'));
    addpath(fullfile(base_dir, 'simulation'));
    addpath(fullfile(base_dir, 'visualization'));
    addpath(fullfile(base_dir, 'evaluation'));
    
    num_runs = 10;
    results = baseline_simulation('proportional', num_runs);
    
    fprintf('\n=== Proportional Algorithm Results ===\n');
    fprintf('Fairness:   %.4f ± %.4f\n', mean(results.fairness), std(results.fairness));
    fprintf('Throughput: %.2f ± %.2f Mbps\n', mean(results.throughput), std(results.throughput));
    fprintf('Handovers:  %.1f ± %.1f\n\n', mean(results.handovers), std(results.handovers));
    
    output_dir = fullfile(base_dir, 'output', 'data');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    save(fullfile(output_dir, 'experiment_proportional.mat'), 'results');
    fprintf('✓ Results saved to: output/data/experiment_proportional.mat\n\n');
end
