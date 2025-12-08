function weight = calculate_user_priority(request_rate, position, network, params)
    min_dist = inf;
    for i = 1:size(network.wifi_ap_positions, 1)
        d = norm(position - network.wifi_ap_positions(i, :));
        if d < min_dist, min_dist = d; end
    end
    for i = 1:size(network.vlc_ap_positions, 1)
        d = norm(position - network.vlc_ap_positions(i, :));
        if d < min_dist, min_dist = d; end
    end
    
    r_norm = request_rate / 100;
    d_norm = min_dist / 20;
    
    sigmoid_r = 1 / (exp(-r_norm) + 1);
    sigmoid_d = 1 / (exp(-d_norm) + 1);
    
    p = 0.7;
    if isfield(params, 'priority_weight_coefficient')
        p = params.priority_weight_coefficient;
    end
    
    weight = p * sigmoid_r + (1 - p) * sigmoid_d;
end
