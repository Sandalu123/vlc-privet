function actions = define_action_space_reduced()
    handover_thresholds = [0.10, 0.15, 0.20];
    wifi_ratios = [0.5, 0.6, 0.7];
    weight_max_values = [5, 7];
    qos_presets = {
        [0.4, 0.3, 0.2, 0.1],
        [0.35, 0.35, 0.2, 0.1]
    };
    
    action_count = 0;
    total_actions = length(handover_thresholds) * length(wifi_ratios) * ...
                   length(weight_max_values) * length(qos_presets);
    actions = cell(total_actions, 1);
    
    for h = 1:length(handover_thresholds)
        for w = 1:length(wifi_ratios)
            for wm = 1:length(weight_max_values)
                for q = 1:length(qos_presets)
                    action_count = action_count + 1;
                    actions{action_count} = struct(...
                        'handover_threshold', handover_thresholds(h), ...
                        'wifi_capacity_ratio', wifi_ratios(w), ...
                        'vlc_capacity_ratio', 1 - wifi_ratios(w), ...
                        'weight_range_max', weight_max_values(wm), ...
                        'qos_weights', qos_presets{q});
                end
            end
        end
    end
end
