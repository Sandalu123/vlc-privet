function load_penalty = calculate_load_variance(results, t, params)
    if t == 1 || results.total_users(t) == 0
        load_penalty = 0;
        return;
    end
    
    num_wifi_aps = 1;
    num_vlc_aps = size(params.vlc_ap_positions, 1);
    total_aps = num_wifi_aps + num_vlc_aps;
    
    ap_loads = zeros(1, total_aps);
    ap_loads(1) = results.wifi_users(t);
    
    if isfield(results, 'vlc_ap_loads') && length(results.vlc_ap_loads) >= t
        vlc_loads = results.vlc_ap_loads{t};
        if ~isempty(vlc_loads)
            ap_loads(2:end) = vlc_loads;
        end
    else
        ap_loads(2:end) = results.vlc_users(t) / num_vlc_aps;
    end
    
    if results.total_users(t) > 0
        ap_ratios = ap_loads / results.total_users(t);
    else
        load_penalty = 0;
        return;
    end
    
    mean_ratio = 1 / total_aps;
    variance = sum((ap_ratios - mean_ratio).^2) / total_aps;
    
    max_load_ratio = max(ap_ratios);
    concentration_penalty = 0;
    if max_load_ratio > 0.6
        concentration_penalty = (max_load_ratio - 0.6) * 2;
    end
    
    load_penalty = (variance * 10) + concentration_penalty;
    load_penalty = min(load_penalty, 1.0);
end
