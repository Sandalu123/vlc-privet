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
end
