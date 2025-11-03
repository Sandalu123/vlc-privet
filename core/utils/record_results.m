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
end
