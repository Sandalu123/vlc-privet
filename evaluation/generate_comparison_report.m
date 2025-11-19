function generate_comparison_report(comparison)
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    report_dir = fullfile(base_dir, 'output', 'reports');
    if ~exist(report_dir, 'dir')
        mkdir(report_dir);
    end
    
    report_path = fullfile(report_dir, 'comparison_report.txt');
    fid = fopen(report_path, 'w');
    
    fprintf(fid, '╔══════════════════════════════════════════════════════════════╗\n');
    fprintf(fid, '║     VLC-WiFi Hybrid Network - Methods Comparison Report     ║\n');
    fprintf(fid, '╚══════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf(fid, 'Comparison Date: %s\n\n', datestr(now));
    
    fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
    fprintf(fid, '1. WWA (Weight-Weighted Allocation)\n');
    fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
    fprintf(fid, '  Fairness:    %.4f ± %.4f\n', mean(comparison.wwa.fairness), std(comparison.wwa.fairness));
    fprintf(fid, '  Throughput:  %.2f ± %.2f Mbps\n', mean(comparison.wwa.throughput), std(comparison.wwa.throughput));
    fprintf(fid, '  Handovers:   %.1f ± %.1f\n\n', mean(comparison.wwa.handovers), std(comparison.wwa.handovers));
    
    if ~isempty(comparison.rl)
        fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
        fprintf(fid, '2. RL-Enhanced (Q-Learning)\n');
        fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
        fprintf(fid, '  Fairness:    %.4f ± %.4f\n', mean(comparison.rl.fairness), std(comparison.rl.fairness));
        fprintf(fid, '  Throughput:  %.2f ± %.2f Mbps\n', mean(comparison.rl.throughput), std(comparison.rl.throughput));
        fprintf(fid, '  Handovers:   %.1f ± %.1f\n\n', mean(comparison.rl.handovers), std(comparison.rl.handovers));
        
        fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
        fprintf(fid, '3. Performance Improvements (RL vs WWA)\n');
        fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
        best_baseline_fairness = mean(comparison.wwa.fairness);
        improvement = (mean(comparison.rl.fairness) - best_baseline_fairness) / best_baseline_fairness * 100;
        fprintf(fid, '  Fairness Improvement: %+.2f%%\n', improvement);
        
        best_baseline_throughput = mean(comparison.wwa.throughput);
        t_improvement = (mean(comparison.rl.throughput) - best_baseline_throughput) / best_baseline_throughput * 100;
        fprintf(fid, '  Throughput Improvement: %+.2f%%\n', t_improvement);
        
        best_baseline_handovers = mean(comparison.wwa.handovers);
        reduction = (best_baseline_handovers - mean(comparison.rl.handovers)) / best_baseline_handovers * 100;
        fprintf(fid, '  Handover Reduction:   %+.2f%%\n\n', reduction);
    end
    
    fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
    fprintf(fid, 'End of Report\n');
    fprintf(fid, '═══════════════════════════════════════════════════════════════\n');
    
    fclose(fid);
    fprintf('Report saved to: %s\n', report_path);
end
