function results = rl_enhanced_simulation(agent, num_runs)
    if nargin < 2
        num_runs = 1;
    end
    
    all_results = cell(num_runs, 1);
    
    for run = 1:num_runs
        fprintf('RL-Enhanced Run %d/%d...\n', run, num_runs);
        
        addpath('../config');
        addpath('../core/network');
        addpath('../core/users');
        addpath('../core/utils');
        addpath('../algorithms/allocation');
        addpath('../algorithms/rl');
        
        base_params = load_config();
        network = create_network(base_params);
        results = initialize_results(base_params);
        
        actions = define_action_space();
        
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
        end
        
        all_results{run} = results;
    end
    
    if num_runs == 1
        results = all_results{1};
    else
        results = all_results;
    end
end
