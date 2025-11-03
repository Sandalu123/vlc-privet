function plot_training_results(training_stats)
    figure('Position', [100, 100, 1200, 800]);
    
    subplot(2, 3, 1);
    plot(training_stats.episode_rewards, 'b-', 'LineWidth', 1.5);
    title('Episode Rewards');
    xlabel('Episode');
    ylabel('Total Reward');
    grid on;
    
    subplot(2, 3, 2);
    plot(training_stats.episode_fairness, 'r-', 'LineWidth', 1.5);
    title('Average Fairness per Episode');
    xlabel('Episode');
    ylabel('Fairness Index');
    grid on;
    
    subplot(2, 3, 3);
    plot(training_stats.episode_handovers, 'g-', 'LineWidth', 1.5);
    title('Total Handovers per Episode');
    xlabel('Episode');
    ylabel('Handovers');
    grid on;
    
    subplot(2, 3, 4);
    plot(training_stats.epsilon_history, 'm-', 'LineWidth', 1.5);
    title('Exploration Rate (Epsilon)');
    xlabel('Episode');
    ylabel('Epsilon');
    grid on;
    
    subplot(2, 3, 5);
    window = 50;
    smoothed_rewards = movmean(training_stats.episode_rewards, window);
    plot(smoothed_rewards, 'b-', 'LineWidth', 2);
    title('Smoothed Rewards (50-episode avg)');
    xlabel('Episode');
    ylabel('Avg Reward');
    grid on;
    
    subplot(2, 3, 6);
    smoothed_fairness = movmean(training_stats.episode_fairness, window);
    plot(smoothed_fairness, 'r-', 'LineWidth', 2);
    title('Smoothed Fairness (50-episode avg)');
    xlabel('Episode');
    ylabel('Avg Fairness');
    grid on;
    
    sgtitle('RL Training Progress', 'FontSize', 16, 'FontWeight', 'bold');
    
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    output_dir = fullfile(base_dir, 'output', 'plots');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    saveas(gcf, fullfile(output_dir, 'training_progress.png'));
end
