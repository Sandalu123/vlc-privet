function generate_comparison_plots(comparison)
    figure('Position', [100, 100, 1400, 600]);
    
    subplot(1, 3, 1);
    methods = {'WWA', 'RL-Enhanced'};
    fairness_vals = [
        mean(comparison.wwa.fairness)
        mean(comparison.rl.fairness)
    ];
    fairness_stds = [
        std(comparison.wwa.fairness)
        std(comparison.rl.fairness)
    ];
    
    bar(fairness_vals, 'FaceColor', [0.2, 0.6, 0.8]);
    hold on;
    errorbar(1:2, fairness_vals, fairness_stds, 'k.', 'LineWidth', 2);
    set(gca, 'XTickLabel', methods);
    xtickangle(45);
    ylabel('Fairness Index');
    title('Fairness Comparison');
    ylim([0, 1]);
    grid on;
    
    subplot(1, 3, 2);
    throughput_vals = [
        mean(comparison.wwa.throughput)
        mean(comparison.rl.throughput)
    ];
    throughput_stds = [
        std(comparison.wwa.throughput)
        std(comparison.rl.throughput)
    ];
    
    bar(throughput_vals, 'FaceColor', [0.8, 0.3, 0.3]);
    hold on;
    errorbar(1:2, throughput_vals, throughput_stds, 'k.', 'LineWidth', 2);
    set(gca, 'XTickLabel', methods);
    xtickangle(45);
    ylabel('Throughput (Mbps)');
    title('Throughput Comparison');
    grid on;
    
    subplot(1, 3, 3);
    handover_vals = [
        mean(comparison.wwa.handovers)
        mean(comparison.rl.handovers)
    ];
    handover_stds = [
        std(comparison.wwa.handovers)
        std(comparison.rl.handovers)
    ];
    
    bar(handover_vals, 'FaceColor', [0.3, 0.8, 0.3]);
    hold on;
    errorbar(1:2, handover_vals, handover_stds, 'k.', 'LineWidth', 2);
    set(gca, 'XTickLabel', methods);
    xtickangle(45);
    ylabel('Total Handovers');
    title('Handover Comparison');
    grid on;
    
    sgtitle('Methods Comparison', 'FontSize', 16, 'FontWeight', 'bold');
    
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    output_dir = fullfile(base_dir, 'output', 'plots');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    saveas(gcf, fullfile(output_dir, 'methods_comparison.png'));
end
