function allocations = allocate_resources(users, capacity, method)
    if nargin < 3
        method = 'wwa';
    end
    
    if isempty(users)
        allocations = [];
        return;
    end
    
    switch lower(method)
        case 'wwa'
            allocations = wwa_algorithm(users, capacity);
        case 'proportional'
            allocations = proportional_algorithm(users, capacity);
        otherwise
            error('Unknown allocation method: %s', method);
    end
end
