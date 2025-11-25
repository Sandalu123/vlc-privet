function results = initialize_results(params)
    results = struct();
    results.time = 1:params.simulation_time;
    results.fairness = zeros(1, params.simulation_time);
    results.total_users = zeros(1, params.simulation_time);
    results.wifi_users = zeros(1, params.simulation_time);
    results.vlc_users = zeros(1, params.simulation_time);
    results.handovers = zeros(1, params.simulation_time);
    results.avg_allocation = zeros(1, params.simulation_time);
    results.fairness_ul = zeros(1, params.simulation_time);
    results.avg_allocation_ul = zeros(1, params.simulation_time);
end
