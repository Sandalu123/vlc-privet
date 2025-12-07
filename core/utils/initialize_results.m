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
    
    % Initialize Service Metrics
    service_names = fieldnames(params.services);
    results.service_metrics = struct();
    for i = 1:length(service_names)
        s_name = service_names{i};
        results.service_metrics.(s_name).avg_bandwidth = zeros(1, params.simulation_time);
        results.service_metrics.(s_name).avg_latency = zeros(1, params.simulation_time);
        results.service_metrics.(s_name).avg_jitter = zeros(1, params.simulation_time);
        results.service_metrics.(s_name).avg_ber = zeros(1, params.simulation_time);
        results.service_metrics.(s_name).satisfied_users = zeros(1, params.simulation_time);
    end
end
