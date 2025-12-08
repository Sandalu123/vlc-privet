function evaluate_system_performance(results, params)
    fprintf('\n=== System Performance Evaluation ===\n');
    fprintf('Mean Fairness: %.4f\n', mean(results.fairness));
    fprintf('Std Fairness: %.4f\n', std(results.fairness));
    fprintf('Mean Throughput: %.2f Mbps\n', mean(results.avg_allocation));
    fprintf('Total Handovers: %d\n', sum(results.handovers));
    fprintf('Avg Users: %.1f\n', mean(results.total_users));
    
    perf_metrics = struct();
    perf_metrics.fairness_mean = mean(results.fairness);
    perf_metrics.fairness_std = std(results.fairness);
    perf_metrics.throughput_mean = mean(results.avg_allocation);
    perf_metrics.handovers_total = sum(results.handovers);
    perf_metrics.users_avg = mean(results.total_users);
    
    % Find project root and create absolute path
    current_file = mfilename('fullpath');
    [current_dir, ~, ~] = fileparts(current_file);
    project_root = fileparts(current_dir);
    output_dir = fullfile(project_root, 'output', 'data');
    
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    save(fullfile(output_dir, 'performance_metrics.mat'), 'perf_metrics');
end
