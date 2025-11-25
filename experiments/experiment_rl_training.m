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
    config.num_episodes = 10000;
    config.learning_rate = 0.012;
    config.gamma = 0.97;
    config.epsilon_start = 1.0;
    config.epsilon_decay = 0.9997;
    config.epsilon_min = 0.05;
    
    custom_model_path = fullfile(base_dir, 'output', 'custom_checkpoint', 'best_model.mat');
    if exist(custom_model_path, 'file')
        fprintf('Found Custom Best Model at: %s\n', custom_model_path);
        choice = input('Do you want to load this custom model instead of training? (y/n): ', 's');
        if strcmpi(choice, 'y')
            output_dir = fullfile(base_dir, 'output', 'data');
            if ~exist(output_dir, 'dir')
                mkdir(output_dir);
            end
            copyfile(custom_model_path, fullfile(output_dir, 'trained_agent.mat'));
            fprintf('✓ Custom model loaded as trained_agent.mat\n');
            return;
        end
    end
    
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
