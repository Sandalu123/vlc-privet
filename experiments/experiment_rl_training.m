function experiment_rl_training()
    fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║            Experiment: RL Training & Evaluation              ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    script_dir = fileparts(mfilename('fullpath'));
    base_dir = fileparts(script_dir);
    
    addpath(fullfile(base_dir, 'config'));
    addpath(fullfile(base_dir, 'algorithms', 'rl'));
    addpath(fullfile(base_dir, 'visualization'));
    
    config = struct();
    config.num_episodes = 5000;
    config.learning_rate = 0.012;
    config.gamma = 0.97;
    config.epsilon_start = 1.0;
    config.epsilon_decay = 0.9997;
    config.epsilon_min = 0.05;
    
    fprintf('Training RL agent with %d episodes...\n\n', config.num_episodes);
    
    [agent, training_stats] = train_rl_agent(config);
    
    output_dir = fullfile(base_dir, 'output', 'data');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    save(fullfile(output_dir, 'trained_agent.mat'), 'agent');
    save(fullfile(output_dir, 'training_stats.mat'), 'training_stats');
    
    plot_training_results(training_stats);
    
    fprintf('\n✓ Training complete!\n');
    fprintf('  Agent saved to: %s\n', fullfile(output_dir, 'trained_agent.mat'));
end
