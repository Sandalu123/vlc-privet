function users = generate_hybrid_users(params, network, time_step)
    base_users = params.base_num_users;
    user_variation = round(sin(time_step * 0.2) * params.user_change_rate);
    num_users = max(5, base_users + user_variation);
    
    users = struct();
    service_names = fieldnames(params.services);
    
    for i = 1:num_users
        users(i).id = i;
        users(i).x = rand() * network.room_size(1);
        users(i).y = rand() * network.room_size(2);
        users(i).position = [users(i).x, users(i).y];
        users(i).velocity = [rand() * 0.5 - 0.25, rand() * 0.5 - 0.25];
        
        % Assign Service Type based on probabilities
        r = rand();
        cumulative_prob = 0;
        selected_service = params.services.(service_names{1}); % Default
        for s = 1:length(params.service_probabilities)
            cumulative_prob = cumulative_prob + params.service_probabilities(s);
            if r <= cumulative_prob
                selected_service = params.services.(service_names{s});
                break;
            end
        end
        
        users(i).service_type = selected_service.name;
        users(i).weight = selected_service.priority;
        
        % Bandwidth request based on service range
        bw_range = selected_service.bandwidth_range;
        users(i).request = bw_range(1) + rand() * (bw_range(2) - bw_range(1));
        
        % QoS Requirements
        users(i).max_latency = selected_service.max_latency;
        users(i).max_jitter = selected_service.max_jitter;
        users(i).max_ber = selected_service.max_ber;
        
        users(i).current_network = assign_initial_network(users(i).position, network);
        users(i).allocated_bandwidth = 0;
    end
end

function network_id = assign_initial_network(position, network)
    for i = 1:size(network.vlc_ap_positions, 1)
        ap_pos = network.vlc_ap_positions(i, :);
        if norm(position - ap_pos) <= network.vlc_coverage_radius
            network_id = i + 1;
            return;
        end
    end
    network_id = 1;
end
