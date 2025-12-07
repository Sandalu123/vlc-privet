function results = record_results(results, t, users, handover_count, params)
    results.handovers(t) = handover_count;
    results.total_users(t) = length(users);
    results.wifi_users(t) = sum([users.current_network] == 1);
    results.vlc_users(t) = sum([users.current_network] > 1);
    
    requests = [users.request];
    allocations = [users.allocated_bandwidth];
    if ~isempty(requests) && sum(requests) > 0 && sum(allocations) > 0
        ratios = allocations ./ max(requests, 0.01);
        ratios(isinf(ratios)) = 0;
        ratios(isnan(ratios)) = 0;
        if sum(ratios.^2) > 0
            results.fairness(t) = (sum(ratios))^2 / (length(users) * sum(ratios.^2));
        else
            results.fairness(t) = 0.5;
        end
    else
        results.fairness(t) = 0.5;
    end
    results.avg_allocation(t) = mean(allocations);
    
    % Uplink Metrics
    requests_ul = [users.request_ul];
    allocations_ul = [users.allocated_bandwidth_ul];
    if ~isempty(requests_ul) && sum(requests_ul) > 0 && sum(allocations_ul) > 0
        ratios_ul = allocations_ul ./ max(requests_ul, 0.01);
        ratios_ul(isinf(ratios_ul)) = 0;
        ratios_ul(isnan(ratios_ul)) = 0;
        if sum(ratios_ul.^2) > 0
            results.fairness_ul(t) = (sum(ratios_ul))^2 / (length(users) * sum(ratios_ul.^2));
        else
            results.fairness_ul(t) = 0.5;
        end
    else
        results.fairness_ul(t) = 0.5;
    end
    results.avg_allocation_ul(t) = mean(allocations_ul);
    
    % --- Record Per-Service QoS Metrics ---
    if isfield(results, 'service_metrics')
        service_names = fieldnames(results.service_metrics);
        
        for i = 1:length(service_names)
            s_name = service_names{i};
            % Find users belonging to this service (match by service name in params)
            % Note: users(u).service_type holds the display name (e.g., 'Web Browsing')
            % params.services.(s_name).name holds the same display name
            target_service_display_name = params.services.(s_name).name;
            
            % Filter users
            service_users_idx = strcmp({users.service_type}, target_service_display_name);
            service_users = users(service_users_idx);
            
            if isempty(service_users)
                continue;
            end
            
            % 1. Average Bandwidth (Allocated)
            results.service_metrics.(s_name).avg_bandwidth(t) = mean([service_users.allocated_bandwidth]);
            
            % 2. Estimate Latency, Jitter, BER based on current network and distance
            latencies = zeros(1, length(service_users));
            jitters = zeros(1, length(service_users));
            bers = zeros(1, length(service_users));
            satisfied_count = 0;
            
            for u = 1:length(service_users)
                user = service_users(u);
                net_id = user.current_network;
                
                % Determine AP position and max range
                if net_id == 1 % WiFi
                    % Find nearest WiFi AP
                    dists = vecnorm(params.wifi_ap_positions - user.position, 2, 2);
                    [dist, ~] = min(dists);
                    max_range = params.wifi_coverage_radius;
                    
                    base_delay = params.wifi_base_delay;
                    base_jitter = params.wifi_base_jitter;
                    base_ber = params.wifi_base_ber;
                else % VLC
                    % Find specific VLC AP (net_id - 1)
                    if net_id - 1 <= size(params.vlc_ap_positions, 1)
                        ap_pos = params.vlc_ap_positions(net_id - 1, :);
                        dist = norm(user.position - ap_pos);
                    else
                        dist = 0; % Should not happen
                    end
                    max_range = params.vlc_coverage_radius;
                    
                    base_delay = params.vlc_base_delay;
                    base_jitter = params.vlc_base_jitter;
                    base_ber = params.vlc_base_ber;
                end
                
                % Estimate QoS Metrics (Simplified Model)
                % Latency increases with distance
                latencies(u) = base_delay + (dist / max_range) * 5; 
                
                % Jitter increases with distance
                jitters(u) = base_jitter + (dist / max_range) * 2;
                
                % BER increases exponentially with distance
                bers(u) = base_ber * (10 ^ (dist / max_range));
                
                % Check Satisfaction
                if user.allocated_bandwidth >= user.request * 0.9 && ...
                   latencies(u) <= user.max_latency && ...
                   jitters(u) <= user.max_jitter && ...
                   bers(u) <= user.max_ber
                    satisfied_count = satisfied_count + 1;
                end
            end
            
            results.service_metrics.(s_name).avg_latency(t) = mean(latencies);
            results.service_metrics.(s_name).avg_jitter(t) = mean(jitters);
            results.service_metrics.(s_name).avg_ber(t) = mean(bers);
            results.service_metrics.(s_name).satisfied_users(t) = satisfied_count;
        end
    end
end
