function users = update_user_movement(users, params, network, time_step)
    % Calculate target user count based on time
    base_users = params.base_num_users;
    user_variation = round(sin(time_step * 0.2) * params.user_change_rate);
    target_num_users = max(5, base_users + user_variation);
    
    current_num_users = length(users);
    
    % Add users if needed
    if target_num_users > current_num_users
        num_to_add = target_num_users - current_num_users;
        service_names = fieldnames(params.services);
        
        for i = 1:num_to_add
            new_idx = current_num_users + i;
            users(new_idx).id = new_idx;
            users(new_idx).x = rand() * network.room_size(1);
            users(new_idx).y = rand() * network.room_size(2);
            users(new_idx).position = [users(new_idx).x, users(new_idx).y];
            users(new_idx).velocity = [rand() * 0.5 - 0.25, rand() * 0.5 - 0.25];
            
            % Assign Service Type
            r = rand();
            cumulative_prob = 0;
            selected_service = params.services.(service_names{1});
            for s = 1:length(params.service_probabilities)
                cumulative_prob = cumulative_prob + params.service_probabilities(s);
                if r <= cumulative_prob
                    selected_service = params.services.(service_names{s});
                    break;
                end
            end
            
            users(new_idx).service_type = selected_service.name;
            users(new_idx).service_priority = selected_service.priority;
            
            bw_range = selected_service.bandwidth_range;
            users(new_idx).request = bw_range(1) + rand() * (bw_range(2) - bw_range(1));
            users(new_idx).weight = calculate_user_priority(users(new_idx).request, users(new_idx).position, network, params);
            users(new_idx).request_ul = users(new_idx).request * (0.2 + 0.3 * rand());
            
            users(new_idx).max_latency = selected_service.max_latency;
            users(new_idx).max_jitter = selected_service.max_jitter;
            users(new_idx).max_ber = selected_service.max_ber;
            
            users(new_idx).current_network = assign_initial_network(users(new_idx).position, network);
            users(new_idx).allocated_bandwidth = 0;
            users(new_idx).allocated_bandwidth_ul = 0;
        end
    % Remove users if needed
    elseif target_num_users < current_num_users
        num_to_remove = current_num_users - target_num_users;
        % Remove from the end
        users = users(1:current_num_users - num_to_remove);
    end
    
    % Update movement for all remaining users
    for i = 1:length(users)
        users(i).x = users(i).x + users(i).velocity(1);
        users(i).y = users(i).y + users(i).velocity(2);
        
        if users(i).x < 0 || users(i).x > network.room_size(1)
            users(i).velocity(1) = -users(i).velocity(1);
            users(i).x = max(0, min(network.room_size(1), users(i).x));
        end
        if users(i).y < 0 || users(i).y > network.room_size(2)
            users(i).velocity(2) = -users(i).velocity(2);
            users(i).y = max(0, min(network.room_size(2), users(i).y));
        end
        
        users(i).position = [users(i).x, users(i).y];
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
