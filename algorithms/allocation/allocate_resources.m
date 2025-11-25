function allocations = allocate_resources(users, capacity, method, direction)
    if nargin < 3
        method = 'wwa';
    end
    if nargin < 4
        direction = 'downlink';
    end
    
    if isempty(users)
        allocations = [];
        return;
    end
    
    % Prepare users for allocation based on direction
    if strcmp(direction, 'uplink')
        for i = 1:length(users)
            users(i).request = users(i).request_ul;
        end
    end
    
    switch lower(method)
        case 'wwa'
            allocations = wwa_algorithm(users, capacity);
        otherwise
            error('Unknown allocation method: %s', method);
    end
end
