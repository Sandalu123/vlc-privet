function experiment_full_comparison()
    fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║         Experiment: Full Methods Comparison                  ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    addpath(fullfile(base_dir, 'config'));
    addpath(fullfile(base_dir, 'core', 'network'));
    addpath(fullfile(base_dir, 'core', 'users'));
    addpath(fullfile(base_dir, 'core', 'utils'));
    addpath(fullfile(base_dir, 'algorithms', 'allocation'));
    addpath(fullfile(base_dir, 'algorithms', 'rl'));
    addpath(fullfile(base_dir, 'simulation'));
    addpath(fullfile(base_dir, 'visualization'));
    addpath(fullfile(base_dir, 'evaluation'));
    
    num_runs = 10;
    
    compare_all_methods(num_runs);
    
    fprintf('\n✓ Full comparison experiment complete!\n\n');
end
