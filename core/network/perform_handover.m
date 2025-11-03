function [users, handover_count] = perform_handover(users, network, params)
    handover_count = 0;
    
    for i = 1:length(users)
        available_nets = find_available_networks(users(i).position, network);
        
        if isempty(available_nets)
            users(i).current_network = 1;
            continue;
        end
        
        scores = calculate_network_scores(users(i), available_nets, network, params);
        [best_score, best_idx] = max([scores.score]);
        best_network = available_nets(best_idx);
        
        current_score = 0;
        for j = 1:length(scores)
            if scores(j).network_id == users(i).current_network
                current_score = scores(j).score;
                break;
            end
        end
        
        if best_network ~= users(i).current_network && best_score > current_score + params.handover_threshold
            users(i).current_network = best_network;
            handover_count = handover_count + 1;
        end
    end
end

function available_nets = find_available_networks(position, network)
    available_nets = [];
    
    for i = 1:size(network.wifi_ap_positions, 1)
        if norm(position - network.wifi_ap_positions(i, :)) <= network.wifi_coverage_radius
            available_nets = [available_nets, 1];
            break;
        end
    end
    
    for i = 1:size(network.vlc_ap_positions, 1)
        if norm(position - network.vlc_ap_positions(i, :)) <= network.vlc_coverage_radius
            available_nets = [available_nets, i + 1];
        end
    end
    
    available_nets = unique(available_nets);
end

function scores = calculate_network_scores(user, available_nets, network, params)
    scores = struct('network_id', {}, 'score', {});
    
    for i = 1:length(available_nets)
        net_id = available_nets(i);
        qos = calculate_qos(user, net_id, network, params);
        score = fuzzy_score(qos);
        scores(i).network_id = net_id;
        scores(i).score = score;
    end
end

function qos = calculate_qos(user, network_id, network, params)
    if network_id == 1
        distances = sqrt(sum((network.wifi_ap_positions - user.position).^2, 2));
        [distance, ~] = min(distances);
        max_bw = network.wifi_capacity / 5;
        max_range = network.wifi_coverage_radius;
        base_delay = params.wifi_base_delay;
        base_jitter = params.wifi_base_jitter;
    else
        vlc_idx = network_id - 1;
        ap_pos = network.vlc_ap_positions(vlc_idx, :);
        distance = norm(user.position - ap_pos);
        max_bw = network.vlc_capacity / 3;
        max_range = network.vlc_coverage_radius;
        base_delay = params.vlc_base_delay;
        base_jitter = params.vlc_base_jitter;
    end
    
    qos = struct();
    qos.bandwidth = max_bw * (1 - 0.7 * distance / max_range) * (0.9 + rand() * 0.2);
    qos.delay = base_delay + (distance / max_range) * 10 + rand() * 2;
    qos.jitter = base_jitter + (distance / max_range) * 5 + rand();
    qos.ber = 1e-6 * (1 + distance / max_range * 10);
end

function score = fuzzy_score(qos)
    bw_norm = min(1, max(0, qos.bandwidth / 30));
    delay_norm = max(0, min(1, 1 - qos.delay / 50));
    jitter_norm = max(0, min(1, 1 - qos.jitter / 20));
    ber_norm = max(0, min(1, 1 - log10(max(qos.ber, 1e-10)) / -3));
    
    weights = [0.4, 0.3, 0.2, 0.1];
    score = weights(1) * bw_norm + weights(2) * delay_norm + ...
            weights(3) * jitter_norm + weights(4) * ber_norm;
end
