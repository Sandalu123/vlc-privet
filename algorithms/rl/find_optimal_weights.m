function [weights, normalization] = find_optimal_weights(fairness, throughput, handovers)
    % find_optimal_weights - Calculates optimal scoring weights using Grid Search
    %
    % Inputs:
    %   fairness:   Vector of fairness values
    %   throughput: Vector of throughput values
    %   handovers:  Vector of handover counts
    %
    % Outputs:
    %   weights:       Struct with fields x (fairness), y (throughput), z (handovers)
    %   normalization: Struct with min/max values for each metric
    
    fprintf('Finding optimal weights using Grid Search...\n');
    
    data = [fairness(:), throughput(:), handovers(:)];
    
    % 1. Normalize all 3 columns to [0,1]
    normalization = struct();
    normalization.min_f = min(data(:,1)); normalization.max_f = max(data(:,1));
    normalization.min_t = min(data(:,2)); normalization.max_t = max(data(:,2));
    normalization.min_h = min(data(:,3)); normalization.max_h = max(data(:,3));
    
    % Avoid division by zero
    if normalization.max_f == normalization.min_f, normalization.max_f = normalization.min_f + 1; end
    if normalization.max_t == normalization.min_t, normalization.max_t = normalization.min_t + 1; end
    if normalization.max_h == normalization.min_h, normalization.max_h = normalization.min_h + 1; end
    
    data_norm = zeros(size(data));
    data_norm(:,1) = (data(:,1) - normalization.min_f) / (normalization.max_f - normalization.min_f);
    data_norm(:,2) = (data(:,2) - normalization.min_t) / (normalization.max_t - normalization.min_t);
    data_norm(:,3) = (data(:,3) - normalization.min_h) / (normalization.max_h - normalization.min_h);
    
    f = data_norm(:,1);
    t = data_norm(:,2);
    % Convert handovers to a 'benefit' form (lower handovers = better)
    h_benefit = 1 - data_norm(:,3);
    
    features = [f, t, h_benefit];
    
    % 2. Grid search for weights on simplex (x + y + z = 1)
    % Constrained: minimum weight = 0.15 (ensures all metrics contribute)
    step = 0.05;
    vals = 0.15:step:0.70;
    
    results = [];  % store mean score and weights
    
    for x = vals
        for y = vals
            z = 1 - (x + y);
            
            if z < 0.15 || z > 0.70
                continue;
            end
            
            % combined score for all rows
            score = x * features(:,1) + y * features(:,2) + z * features(:,3);
            
            results = [results; mean(score), std(score), x, y, z];
        end
    end
    
    % 3. Sort by mean score (descending: higher = better)
    results_sorted = sortrows(results, -1); 
    
    top1 = results_sorted(1, :);
    
    weights = struct();
    weights.x = top1(3); % Fairness weight
    weights.y = top1(4); % Throughput weight
    weights.z = top1(5); % Handovers benefit weight
    
    fprintf('Optimal Weights Found:\n');
    fprintf('  Fairness (x):   %.2f\n', weights.x);
    fprintf('  Throughput (y): %.2f\n', weights.y);
    fprintf('  Handovers (z):  %.2f (applied to 1-normalized_handovers)\n', weights.z);
    fprintf('  Max Mean Score: %.4f\n\n', top1(1));
    
    % --- PCA Analysis (For Reference) ---
    try
        [coeff,~,~,~,~] = pca(features);
        pc1 = coeff(:,1);     % first principal component direction
        
        % Ensure non-negative and sum to 1
        pc1 = abs(pc1); % Take magnitude
        pc1 = pc1 / sum(pc1);
        
        fprintf('PCA-based weights (Reference):\n');
        fprintf('  x (fairness)   = %.4f\n', pc1(1));
        fprintf('  y (throughput) = %.4f\n', pc1(2));
        fprintf('  z (h-benefit)  = %.4f\n\n', pc1(3));
    catch
        fprintf('PCA calculation failed (likely insufficient data variance).\n\n');
    end
end
