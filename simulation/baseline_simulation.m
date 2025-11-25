function results = baseline_simulation(allocation_method, num_runs)
    if nargin < 1
        allocation_method = 'wwa';
    end
    if nargin < 2
        num_runs = 1;
    end
    
    addpath(genpath('..'));
    
    if num_runs == 1
        results = run_single_simulation(allocation_method);
    else
        results = run_multiple_simulations(allocation_method, num_runs);
    end
end

function results = run_single_simulation(allocation_method)
    params = load_config();
    network = create_network(params);
    results = initialize_results(params);
    
    for t = 1:params.simulation_time
        if t == 1
            users = create_hybrid_users(params, network, t);
        else
            users = update_user_movement(users, params, network);
        end
        
        [users, handover_count] = perform_handover(users, network, params);
        
        [wifi_users, vlc_users] = split_users_by_network(users);
        
        % Downlink Allocation
        wifi_alloc = allocate_resources(wifi_users, params.wifi_capacity, allocation_method, 'downlink');
        vlc_alloc = allocate_resources(vlc_users, params.vlc_capacity, allocation_method, 'downlink');
        
        % Uplink Allocation
        wifi_alloc_ul = allocate_resources(wifi_users, params.wifi_capacity_ul, allocation_method, 'uplink');
        vlc_alloc_ul = allocate_resources(vlc_users, params.vlc_capacity_ul, allocation_method, 'uplink');
        
        users = merge_allocations(users, wifi_users, vlc_users, wifi_alloc, vlc_alloc, wifi_alloc_ul, vlc_alloc_ul);
        
        results = record_results(results, t, users, handover_count, params);
        
        if mod(t, 10) == 0
            fprintf('Time: %d, Users: %d (WiFi: %d, VLC: %d), Handovers: %d, Fairness: %.3f\n', ...
                t, length(users), length(wifi_users), length(vlc_users), handover_count, results.fairness(t));
        end
    end
    
    fprintf('\n=== Baseline Simulation Results (%s) ===\n', upper(allocation_method));
    fprintf('Mean Fairness: %.4f\n', mean(results.fairness));
    fprintf('Total Handovers: %d\n', sum(results.handovers));
    fprintf('Avg Handovers/Step: %.2f\n', mean(results.handovers));
end

function results = run_multiple_simulations(allocation_method, num_runs)
    fprintf('Running %d simulations with %s allocation...\n', num_runs, upper(allocation_method));
    
    all_fairness = zeros(1, num_runs);
    all_throughput = zeros(1, num_runs);
    all_handovers = zeros(1, num_runs);
    
    for run = 1:num_runs
        fprintf('  Run %d/%d... ', run, num_runs);
        
        params = load_config();
        network = create_network(params);
        sim_results = initialize_results(params);
        
        for t = 1:params.simulation_time
            if t == 1
                users = create_hybrid_users(params, network, t);
            else
                users = update_user_movement(users, params, network);
            end
            
            [users, handover_count] = perform_handover(users, network, params);
            [wifi_users, vlc_users] = split_users_by_network(users);
            
            % Downlink Allocation
            wifi_alloc = allocate_resources(wifi_users, params.wifi_capacity, allocation_method, 'downlink');
            vlc_alloc = allocate_resources(vlc_users, params.vlc_capacity, allocation_method, 'downlink');
            
            % Uplink Allocation
            wifi_alloc_ul = allocate_resources(wifi_users, params.wifi_capacity_ul, allocation_method, 'uplink');
            vlc_alloc_ul = allocate_resources(vlc_users, params.vlc_capacity_ul, allocation_method, 'uplink');
            
            users = merge_allocations(users, wifi_users, vlc_users, wifi_alloc, vlc_alloc, wifi_alloc_ul, vlc_alloc_ul);
            sim_results = record_results(sim_results, t, users, handover_count, params);
        end
        
        all_fairness(run) = mean(sim_results.fairness);
        all_throughput(run) = mean(sim_results.avg_allocation);
        all_handovers(run) = sum(sim_results.handovers);
        
        fprintf('Fairness: %.4f, Handovers: %d\n', all_fairness(run), all_handovers(run));
    end
    
    results = struct();
    results.fairness = all_fairness;
    results.throughput = all_throughput;
    results.handovers = all_handovers;
    results.allocation_method = allocation_method;
    results.num_runs = num_runs;
    
    fprintf('\n=== Summary (%d runs, %s) ===\n', num_runs, upper(allocation_method));
    fprintf('Fairness:   %.4f ± %.4f\n', mean(all_fairness), std(all_fairness));
    fprintf('Throughput: %.2f ± %.2f Mbps\n', mean(all_throughput), std(all_throughput));
    fprintf('Handovers:  %.1f ± %.1f\n', mean(all_handovers), std(all_handovers));
end
