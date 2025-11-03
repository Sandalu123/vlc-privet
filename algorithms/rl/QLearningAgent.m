classdef QLearningAgent < handle
    properties
        Q_table
        learning_rate
        discount_factor
        epsilon
        epsilon_decay
        epsilon_min
        num_actions
        state_dim
        bins_per_dim
        state_bins
        state_counts
    end
    
    methods
        function obj = QLearningAgent(config)
            obj.learning_rate = config.learning_rate;
            obj.discount_factor = config.gamma;
            obj.epsilon = config.epsilon_start;
            obj.epsilon_decay = config.epsilon_decay;
            obj.epsilon_min = config.epsilon_min;
            obj.num_actions = config.num_actions;
            obj.state_dim = config.state_dim;
            obj.bins_per_dim = config.bins_per_dim;
            
            total_states = obj.bins_per_dim ^ obj.state_dim;
            obj.Q_table = zeros(total_states, obj.num_actions);
            obj.state_bins = linspace(0, 1, obj.bins_per_dim + 1);
            obj.state_counts = zeros(total_states, 1);
        end
        
        function action = select_action(obj, state)
            if rand() < obj.epsilon
                action = randi(obj.num_actions);
            else
                state_idx = obj.discretize_state(state);
                q_values = obj.Q_table(state_idx, :);
                
                max_q = max(q_values);
                best_actions = find(q_values == max_q);
                action = best_actions(randi(length(best_actions)));
            end
        end
        
        function update(obj, state, action, reward, next_state)
            state_idx = obj.discretize_state(state);
            next_state_idx = obj.discretize_state(next_state);
            
            obj.state_counts(state_idx) = obj.state_counts(state_idx) + 1;
            
            best_next_Q = max(obj.Q_table(next_state_idx, :));
            
            current_Q = obj.Q_table(state_idx, action);
            target_Q = reward + obj.discount_factor * best_next_Q;
            
            obj.Q_table(state_idx, action) = current_Q + ...
                obj.learning_rate * (target_Q - current_Q);
        end
        
        function decay_epsilon(obj)
            obj.epsilon = max(obj.epsilon_min, obj.epsilon * obj.epsilon_decay);
        end
        
        function state_idx = discretize_state(obj, state)
            key_features = [
                state(6)
                state(9)
                state(4)
                state(5)
                state(8)
                state(3)
            ];
            
            key_features = key_features(1:obj.state_dim);
            
            indices = zeros(1, obj.state_dim);
            for i = 1:obj.state_dim
                val = min(max(key_features(i), 0), 1.5);
                bin_idx = find(val >= obj.state_bins(1:end-1) & val < obj.state_bins(2:end), 1);
                if isempty(bin_idx)
                    if val >= obj.state_bins(end)
                        bin_idx = obj.bins_per_dim;
                    else
                        bin_idx = 1;
                    end
                end
                indices(i) = bin_idx;
            end
            
            state_idx = 1;
            multiplier = 1;
            for i = 1:obj.state_dim
                state_idx = state_idx + (indices(i) - 1) * multiplier;
                multiplier = multiplier * obj.bins_per_dim;
            end
            state_idx = max(1, min(obj.bins_per_dim^obj.state_dim, state_idx));
        end
        
        function save(obj, filename)
            Q_table = obj.Q_table;
            epsilon = obj.epsilon;
            state_counts = obj.state_counts;
            learning_rate = obj.learning_rate;
            discount_factor = obj.discount_factor;
            state_dim = obj.state_dim;
            bins_per_dim = obj.bins_per_dim;
            save(filename, 'Q_table', 'epsilon', 'state_counts', 'learning_rate', ...
                'discount_factor', 'state_dim', 'bins_per_dim');
        end
        
        function load(obj, filename)
            data = load(filename);
            obj.Q_table = data.Q_table;
            if isfield(data, 'epsilon')
                obj.epsilon = data.epsilon;
            end
            if isfield(data, 'state_counts')
                obj.state_counts = data.state_counts;
            end
        end
        
        function coverage = get_coverage(obj)
            visited = obj.Q_table ~= 0;
            coverage = (sum(visited(:)) / numel(obj.Q_table)) * 100;
        end
    end
end
