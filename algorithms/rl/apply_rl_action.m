function params = apply_rl_action(action_id, actions, base_params)
    action = actions{action_id};
    
    params = base_params;
    
    params.handover_threshold = action.handover_threshold;
    params.wifi_capacity_ratio = action.wifi_capacity_ratio;
    params.vlc_capacity_ratio = action.vlc_capacity_ratio;
    params.weight_range = [1, action.weight_range_max];
    params.allocation_method = action.allocation_method;
    params.qos_weights = action.qos_weights;
    
    params.wifi_capacity = params.total_capacity * params.wifi_capacity_ratio;
    params.vlc_capacity = params.total_capacity * params.vlc_capacity_ratio;
end
