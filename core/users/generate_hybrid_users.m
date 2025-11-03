function users = generate_hybrid_users(params, network, time_step)
    base_users = params.base_num_users;
    user_variation = round(sin(time_step * 0.2) * params.user_change_rate);
    num_users = max(5, base_users + user_variation);
    
    users = struct();
    for i = 1:num_users
        users(i).id = i;
        users(i).x = rand() * network.room_size(1);
        users(i).y = rand() * network.room_size(2);
        users(i).position = [users(i).x, users(i).y];
        users(i).velocity = [rand() * 0.5 - 0.25, rand() * 0.5 - 0.25];
        users(i).weight = randi(params.weight_range);
        users(i).request = params.request_range(1) + rand() * diff(params.request_range);
        users(i).request = users(i).request * (0.8 + rand() * 0.4);
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
