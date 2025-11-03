function plot_simulation_results(results, title_str)
    if nargin < 2
        title_str = 'Network Performance';
    end
    
    figure('Position', [50, 50, 1400, 900]);
    
    subplot(3, 3, 1);
    plot(results.time, results.fairness, 'b-', 'LineWidth', 2);
    grid on;
    title('Fairness Index Over Time');
    xlabel('Time Steps');
    ylabel('Fairness Index');
    
    subplot(3, 3, 2);
    plot(results.time, results.total_users, 'k-', 'LineWidth', 2);
    hold on;
    plot(results.time, results.wifi_users, 'b--', 'LineWidth', 1.5);
    plot(results.time, results.vlc_users, 'r--', 'LineWidth', 1.5);
    legend('Total', 'WiFi', 'VLC');
    grid on;
    title('User Distribution');
    xlabel('Time Steps');
    ylabel('Number of Users');
    
    subplot(3, 3, 3);
    stem(results.time, results.handovers, 'filled', 'MarkerSize', 4);
    grid on;
    title('Handover Events');
    xlabel('Time Steps');
    ylabel('Handovers per Step');
    
    subplot(3, 3, 4);
    histogram(results.fairness, 20, 'FaceColor', 'blue', 'FaceAlpha', 0.7);
    title('Fairness Distribution');
    xlabel('Fairness Index');
    ylabel('Frequency');
    
    subplot(3, 3, 5);
    plot(results.time, results.avg_allocation, 'm-', 'LineWidth', 2);
    grid on;
    title('Average Bandwidth Allocation');
    xlabel('Time Steps');
    ylabel('Bandwidth (Mbps)');
    
    subplot(3, 3, 6);
    yyaxis left;
    plot(results.time, results.fairness, 'b-', 'LineWidth', 2);
    ylabel('Fairness', 'Color', 'b');
    yyaxis right;
    plot(results.time, results.handovers, 'r-', 'LineWidth', 2);
    ylabel('Handovers', 'Color', 'r');
    title('Fairness vs Handovers');
    xlabel('Time Steps');
    grid on;
    
    subplot(3, 3, 7);
    smoothed = movmean(results.fairness, 5);
    plot(results.time, results.fairness, 'b:', 'LineWidth', 1);
    hold on;
    plot(results.time, smoothed, 'r-', 'LineWidth', 2);
    legend('Original', 'Smoothed');
    title('Smoothed Fairness');
    xlabel('Time Steps');
    ylabel('Fairness Index');
    grid on;
    
    subplot(3, 3, 8);
    wifi_ratio = results.wifi_users ./ results.total_users * 100;
    vlc_ratio = results.vlc_users ./ results.total_users * 100;
    area(results.time, [wifi_ratio; vlc_ratio]');
    legend('WiFi %', 'VLC %');
    title('Network Load Distribution');
    xlabel('Time Steps');
    ylabel('Percentage (%)');
    grid on;
    
    subplot(3, 3, 9);
    cumulative_handovers = cumsum(results.handovers);
    plot(results.time, cumulative_handovers, 'g-', 'LineWidth', 2);
    title('Cumulative Handovers');
    xlabel('Time Steps');
    ylabel('Total Handovers');
    grid on;
    
    sgtitle(title_str, 'FontSize', 16, 'FontWeight', 'bold');
    
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    output_dir = fullfile(base_dir, 'output', 'plots');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    filename = sprintf('%s/simulation_%s.png', output_dir, strrep(lower(title_str), ' ', '_'));
    saveas(gcf, filename);
end
