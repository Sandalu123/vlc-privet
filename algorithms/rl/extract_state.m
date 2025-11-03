function state = extract_state(users, network, results, t)
    if isempty(users)
        state = zeros(1, 12);
        return;
    end
    
    num_users = length(users);
    state = zeros(1, 12);
    
    state(1) = results.wifi_users(t) / max(results.total_users(t), 1);
    state(2) = results.vlc_users(t) / max(results.total_users(t), 1);
    state(3) = min(1.0, results.total_users(t) / 30);
    
    wifi_demand = 0;
    vlc_demand = 0;
    for i = 1:num_users
        if users(i).current_network == 1
            wifi_demand = wifi_demand + users(i).request;
        else
            vlc_demand = vlc_demand + users(i).request;
        end
    end
    
    state(4) = min(1.0, wifi_demand / max(network.wifi_capacity, 0.1));
    state(5) = min(1.0, vlc_demand / max(network.vlc_capacity, 0.1));
    
    if results.fairness(t) > 0
        state(6) = results.fairness(t);
    else
        state(6) = 0.5;
    end
    
    distances = zeros(1, num_users);
    for i = 1:num_users
        wifi_dists = sqrt(sum((network.wifi_ap_positions - users(i).position).^2, 2));
        vlc_dists = sqrt(sum((network.vlc_ap_positions - users(i).position).^2, 2));
        all_dists = [wifi_dists; vlc_dists];
        distances(i) = min(all_dists);
    end
    state(7) = min(1.0, mean(distances) / 20);
    
    state(8) = min(1.0, results.handovers(t) / max(results.total_users(t), 1));
    
    state(9) = min(1.0, results.avg_allocation(t) / 10);
    
    room_area = network.room_size(1) * network.room_size(2);
    wifi_area = pi * network.wifi_coverage_radius^2 * size(network.wifi_ap_positions, 1);
    vlc_area = pi * network.vlc_coverage_radius^2 * size(network.vlc_ap_positions, 1);
    total_ap_area = wifi_area + vlc_area;
    
    coverage_ratio = min(1.0, total_ap_area / room_area);
    user_density_normalized = (results.total_users(t) / 30) * coverage_ratio;
    state(10) = min(1.0, user_density_normalized);
    
    if t >= 5
        past_fairness = results.fairness(max(1, t-9):t-5);
        recent_fairness = results.fairness(max(1, t-4):t);
        
        past_fairness = past_fairness(past_fairness > 0);
        recent_fairness = recent_fairness(recent_fairness > 0);
        
        if ~isempty(past_fairness) && ~isempty(recent_fairness)
            fairness_trend = mean(recent_fairness) / max(mean(past_fairness), 0.1);
            state(11) = min(1.5, fairness_trend);
        else
            state(11) = 1.0;
        end
        
        state(12) = min(1.0, mean(results.handovers(max(1, t-4):t)) / 5);
    else
        state(11) = 1.0;
        state(12) = min(1.0, results.handovers(t) / 5);
    end
    
    state(isnan(state)) = 0.5;
    state(isinf(state)) = 0.5;
    state = max(0, min(1.5, state));
end
