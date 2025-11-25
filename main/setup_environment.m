function setup_environment()
    close all; clc;
    warning('off', 'all');
    
    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║           Environment Setup & Verification                  ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    base_path = fileparts(fileparts(mfilename('fullpath')));
    
    fprintf('1. Adding paths to MATLAB search path...\n');
    paths_to_add = {
        fullfile(base_path, 'config')
        fullfile(base_path, 'core', 'network')
        fullfile(base_path, 'core', 'users')
        fullfile(base_path, 'core', 'utils')
        fullfile(base_path, 'algorithms', 'allocation')
        fullfile(base_path, 'algorithms', 'rl')
        fullfile(base_path, 'simulation')
        fullfile(base_path, 'evaluation')
        fullfile(base_path, 'visualization')
        fullfile(base_path, 'experiments')
    };
    
    for i = 1:length(paths_to_add)
        addpath(paths_to_add{i});
        fprintf('  ✓ Added: %s\n', paths_to_add{i});
    end
    
    fprintf('\n2. Checking required files...\n');
    required_files = {
        'load_config.m'
        'create_network.m'
        'create_hybrid_users.m'
        'wwa_algorithm.m'
        'wwa_algorithm.m'
        'QLearningAgent.m'
        'baseline_simulation.m'
    };
    
    all_files_exist = true;
    for i = 1:length(required_files)
        if exist(required_files{i}, 'file') == 2
            fprintf('  ✓ %s\n', required_files{i});
        else
            fprintf('  ✗ %s - MISSING\n', required_files{i});
            all_files_exist = false;
        end
    end
    
    if ~all_files_exist
        fprintf('\n✗ Some required files are missing!\n');
        return;
    end
    
    fprintf('\n3. Testing core functions...\n');
    
    try
        params = load_config();
        params = load_config();
        fprintf('  ✓ load_config() works (Version: %s)\n', params.version);
    catch ME
        fprintf('  ✗ load_config() failed: %s\n', ME.message);
        return;
    end
    
    try
        network = create_network(params);
        fprintf('  ✓ create_network() works\n');
    catch ME
        fprintf('  ✗ create_network() failed: %s\n', ME.message);
        return;
    end
    
    try
        users = create_hybrid_users(params, network, 1);
        fprintf('  ✓ create_hybrid_users() works - %d users created\n', length(users));
    catch ME
        fprintf('  ✗ create_hybrid_users() failed: %s\n', ME.message);
        return;
    end
    
    fprintf('\n4. Verifying output directories...\n');
    output_dirs = {
        fullfile(base_path, 'output', 'data')
        fullfile(base_path, 'output', 'plots')
        fullfile(base_path, 'output', 'reports')
    };
    
    for i = 1:length(output_dirs)
        if ~exist(output_dirs{i}, 'dir')
            mkdir(output_dirs{i});
            fprintf('  ✓ Created: %s\n', output_dirs{i});
        else
            fprintf('  ✓ Exists: %s\n', output_dirs{i});
        end
    end
    
    fprintf('\n5. Configuration Summary:\n');
    fprintf('  Network Capacity: %d Mbps\n', params.total_capacity);
    fprintf('  WiFi APs: %d\n', size(params.wifi_ap_positions, 1));
    fprintf('  VLC APs: %d\n', size(params.vlc_ap_positions, 1));
    fprintf('  Simulation Time: %d steps\n', params.simulation_time);
    fprintf('  Base Users: %d\n', params.base_num_users);
    
    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║           ✓ Environment Setup Complete!                     ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf('You can now run experiments using main_pipeline()\n\n');
end
