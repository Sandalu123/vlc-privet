function allocations = wwa_algorithm(users, total_capacity)
    if isempty(users)
        allocations = [];
        return;
    end
    
    n = length(users);
    requests = [users.request];
    weights = [users.weight];
    
    if mod(n, 2) == 1
        unions = create_odd_unions(requests, n);
    else
        unions = create_even_unions(requests, n);
    end
    
    union_totals = cellfun(@sum, unions);
    total_demand = sum(union_totals);
    
    if total_demand == 0
        allocations = zeros(1, n);
        return;
    end
    
    group_allocations = (union_totals / total_demand) * total_capacity;
    
    allocations = zeros(1, n);
    user_idx = 1;
    
    for g = 1:length(unions)
        group_users = length(unions{g});
        if group_users == 1
            allocations(user_idx) = group_allocations(g);
        else
            group_weights = weights(user_idx:user_idx+group_users-1);
            weight_sum = sum(group_weights);
            if weight_sum > 0
                for j = 1:group_users
                    allocations(user_idx + j - 1) = group_allocations(g) * (group_weights(j) / weight_sum);
                end
            else
                for j = 1:group_users
                    allocations(user_idx + j - 1) = group_allocations(g) / group_users;
                end
            end
        end
        user_idx = user_idx + group_users;
    end
    
    for i = 1:n
        allocations(i) = min(allocations(i), requests(i));
    end
end

function unions = create_odd_unions(requests, n)
    unions = cell((n + 1) / 2, 1);
    for i = 1:(n-1)/2
        unions{i} = [requests(i), requests(n + 1 - i)];
    end
    unions{(n + 1) / 2} = [2 * requests((n + 1) / 2)];
end

function unions = create_even_unions(requests, n)
    unions = cell(n / 2, 1);
    for i = 1:n/2
        unions{i} = [requests(i), requests(n + 1 - i)];
    end
end
