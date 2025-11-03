function allocations = proportional_algorithm(users, total_capacity)
    if isempty(users)
        allocations = [];
        return;
    end
    
    requests = [users.request];
    total_requests = sum(requests);
    
    if total_requests == 0
        allocations = zeros(1, length(users));
        return;
    end
    
    allocations = (requests / total_requests) * total_capacity;
end
