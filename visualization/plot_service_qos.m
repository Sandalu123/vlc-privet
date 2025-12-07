function plot_service_qos(results, title_str)
    if nargin < 2
        title_str = 'Service-Based QoS Performance';
    end
    
    if ~isfield(results, 'service_metrics')
        warning('No service metrics found in results.');
        return;
    end
    
    service_names = fieldnames(results.service_metrics);
    num_services = length(service_names);
    
    % Colors for different services
    colors = lines(num_services);
    
    figure('Position', [100, 100, 1200, 800]);
    
    % 1. Average Bandwidth
    subplot(2, 2, 1);
    hold on;
    for i = 1:num_services
        s_name = service_names{i};
        data = results.service_metrics.(s_name).avg_bandwidth;
        plot(results.time, data, 'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', s_name);
    end
    title('Average Bandwidth per Service');
    xlabel('Time Steps');
    ylabel('Bandwidth (Mbps)');
    legend('Location', 'best');
    grid on;
    
    % 2. Average Latency
    subplot(2, 2, 2);
    hold on;
    for i = 1:num_services
        s_name = service_names{i};
        data = results.service_metrics.(s_name).avg_latency;
        plot(results.time, data, 'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', s_name);
    end
    title('Average Latency per Service');
    xlabel('Time Steps');
    ylabel('Latency (ms)');
    grid on;
    
    % 3. Average Jitter
    subplot(2, 2, 3);
    hold on;
    for i = 1:num_services
        s_name = service_names{i};
        data = results.service_metrics.(s_name).avg_jitter;
        plot(results.time, data, 'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', s_name);
    end
    title('Average Jitter per Service');
    xlabel('Time Steps');
    ylabel('Jitter (ms)');
    grid on;
    
    % 4. Average BER (Log Scale)
    subplot(2, 2, 4);
    hold on;
    for i = 1:num_services
        s_name = service_names{i};
        data = results.service_metrics.(s_name).avg_ber;
        % Avoid log(0)
        data(data == 0) = 1e-12;
        semilogy(results.time, data, 'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', s_name);
    end
    title('Average BER per Service');
    xlabel('Time Steps');
    ylabel('Bit Error Rate (log scale)');
    grid on;
    
    sgtitle(title_str, 'FontSize', 16, 'FontWeight', 'bold');
    
    % Save Plot
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    output_dir = fullfile(base_dir, 'output', 'plots');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    filename = sprintf('%s/service_qos_%s.png', output_dir, strrep(lower(title_str), ' ', '_'));
    saveas(gcf, filename);
end
