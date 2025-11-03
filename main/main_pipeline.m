function main_pipeline()
    close all; clear; clc;
    
    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║     VLC-WiFi Hybrid Network - Main Execution Pipeline       ║\n');
    fprintf('║                      Version 2.0                             ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf('Select operation mode:\n');
    fprintf('  1) Setup & Verify Environment\n');
    fprintf('  2) Run WWA Baseline Experiment\n');
    fprintf('  3) Run Proportional Baseline Experiment\n');
    fprintf('  4) Train RL Agent\n');
    fprintf('  5) Run RL-Enhanced Simulation\n');
    fprintf('  6) Compare All Methods\n');
    fprintf('  7) Full Pipeline (All steps)\n');
    fprintf('  8) Exit\n\n');
    
    choice = input('Enter choice (1-8): ');
    
    switch choice
        case 1
            fprintf('\n=== Setup & Verification ===\n');
            setup_environment();
            
        case 2
            fprintf('\n=== WWA Baseline ===\n');
            addpath('experiments');
            experiment_wwa_only();
            
        case 3
            fprintf('\n=== Proportional Baseline ===\n');
            addpath('experiments');
            experiment_proportional_only();
            
        case 4
            fprintf('\n=== RL Training ===\n');
            addpath('experiments');
            experiment_rl_training();
            
        case 5
            fprintf('\n=== RL-Enhanced Simulation ===\n');
            run_rl_enhanced();
            
        case 6
            fprintf('\n=== Compare All Methods ===\n');
            addpath('experiments');
            experiment_full_comparison();
            
        case 7
            fprintf('\n=== Full Pipeline ===\n');
            run_full_pipeline();
            
        case 8
            fprintf('\nExiting...\n');
            return;
            
        otherwise
            fprintf('\nInvalid choice. Exiting...\n');
            return;
    end
    
    fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║                    Operation Complete!                       ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
end

function run_rl_enhanced()
    addpath('simulation');
    addpath('algorithms/rl');
    addpath('visualization');
    
    if ~isfile('output/data/trained_agent.mat')
        fprintf('✗ No trained agent found!\n');
        fprintf('  Please run training first (option 4)\n');
        return;
    end
    
    load('output/data/trained_agent.mat', 'agent');
    results = rl_enhanced_simulation(agent);
    
    plot_simulation_results(results, 'RL-Enhanced Simulation');
    
    fprintf('\n✓ RL-Enhanced simulation complete!\n');
    fprintf('  Plot saved to: output/plots/\n');
end

function run_full_pipeline()
    fprintf('\nThis will run all experiments:\n');
    fprintf('  1. WWA Baseline (10 runs)\n');
    fprintf('  2. Proportional Baseline (10 runs)\n');
    fprintf('  3. RL Training (1000 episodes)\n');
    fprintf('  4. RL Evaluation (10 runs)\n');
    fprintf('  5. Full Comparison & Report\n\n');
    fprintf('Estimated time: 2-3 hours\n\n');
    
    proceed = input('Continue? (y/n): ', 's');
    if ~strcmp(proceed, 'y')
        fprintf('Cancelled.\n');
        return;
    end
    
    addpath('experiments');
    
    fprintf('\n--- Phase 1: WWA Baseline ---\n');
    experiment_wwa_only();
    
    fprintf('\n--- Phase 2: Proportional Baseline ---\n');
    experiment_proportional_only();
    
    fprintf('\n--- Phase 3: RL Training ---\n');
    experiment_rl_training();
    
    fprintf('\n--- Phase 4: Full Comparison ---\n');
    experiment_full_comparison();
    
    fprintf('\n✓ Full pipeline complete!\n');
    fprintf('  All results saved to: output/\n');
end
