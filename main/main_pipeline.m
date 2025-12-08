%test
function main_pipeline()
    close all; clear; clc;
    warning('off', 'all');
    
    % Load version from config
    addpath('config');
    try
        params = load_config();
        version_str = params.version;
    catch
        version_str = 'Unknown';
    end

    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║     VLC-WiFi Hybrid Network - Main Execution Pipeline       ║\n');
    fprintf('║                      Version %-7s                        ║\n', version_str);
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf('Select operation mode:\n');
    fprintf('  1) Setup & Verify Environment\n');
    fprintf('  2) Run WWA Baseline Experiment\n');
    fprintf('  3) Train RL Agent\n');
    fprintf('  4) Run RL-Enhanced Simulation\n');
    fprintf('  5) Compare All Methods\n');
    fprintf('  6) Full Pipeline (All steps)\n');
    fprintf('  7) Exit\n\n');
    
    choice = input('Enter choice (1-7): ');
    
    switch choice
        case 1
            fprintf('\n=== Setup & Verification ===\n');
            setup_environment();
            
        case 2
            fprintf('\n=== WWA Baseline ===\n');
            addpath('experiments');
            experiment_wwa_only();
            
        case 3
            fprintf('\n=== RL Training ===\n');
            addpath('experiments');
            experiment_rl_training();
            
        case 4
            fprintf('\n=== RL-Enhanced Simulation ===\n');
            run_rl_enhanced();
            
        case 5
            fprintf('\n=== Compare All Methods ===\n');
            addpath('experiments');
            experiment_full_comparison();
            
        case 6
            fprintf('\n=== Full Pipeline ===\n');
            run_full_pipeline();
            
        case 7
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
    addpath('core/network');
    addpath('core/users');
    addpath('core/utils');
    addpath('algorithms/allocation');
    
    if ~isfile('output/data/trained_agent.mat')
        fprintf('✗ No trained agent found!\n');
        fprintf('  Please run training first (Option 3)\n');
        return;
    end
    
    load('output/data/trained_agent.mat', 'agent');
    results = rl_enhanced_simulation(agent);
    
    fprintf('\n✓ RL-Enhanced simulation complete!\n');
    fprintf('  Plots saved to: output/plots/\n');
    fprintf('  Metrics saved to: output/data/rl_perf_metrics.mat\n');
end

function run_full_pipeline()
    fprintf('\nThis will run all experiments:\n');
    fprintf('  1. WWA Baseline (10 runs)\n');
    fprintf('  2. RL Training\n');
    fprintf('  3. RL Evaluation (10 runs)\n');
    fprintf('  4. Full Comparison & Report\n\n');
    fprintf('Estimated time: 2-3 hours\n\n');
    
    proceed = input('Continue? (y/n): ', 's');
    if ~strcmp(proceed, 'y')
        fprintf('Cancelled.\n');
        return;
    end
    
    addpath('experiments');
    
    fprintf('\n--- Phase 1: WWA Baseline ---\n');
    experiment_wwa_only();
    
    fprintf('\n--- Phase 2: RL Training ---\n');
    experiment_rl_training();
    
    fprintf('\n--- Phase 3: Full Comparison ---\n');
    experiment_full_comparison();
    
    fprintf('\n✓ Full pipeline complete!\n');
    fprintf('  All results saved to: output/\n');
end
