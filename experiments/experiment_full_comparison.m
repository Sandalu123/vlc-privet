function experiment_full_comparison()
    fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║         Experiment: Full Methods Comparison                  ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    addpath('../evaluation');
    
    num_runs = 10;
    
    compare_all_methods(num_runs);
    
    fprintf('\n✓ Full comparison experiment complete!\n\n');
end
