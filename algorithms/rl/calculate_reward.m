function reward = calculate_reward(results, t)
    if t == 1 || results.fairness(t) == 0
        reward = 0;
        return;
    end
    
    fairness_reward = results.fairness(t) * 15;
    
    handover_penalty = results.handovers(t) * 0.3;
    
    if results.total_users(t) > 0
        avg_utilization = (results.wifi_users(t) + results.vlc_users(t)) / results.total_users(t);
    else
        avg_utilization = 0;
    end
    utilization_bonus = avg_utilization * 3;
    
    throughput_reward = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = results.avg_allocation(t);
        throughput_reward = min(10, avg_throughput * 1.2);
    end
    
    if results.total_users(t) > 1
        balance_ratio = min(results.wifi_users(t), results.vlc_users(t)) / results.total_users(t);
        imbalance_penalty = max(0, (0.5 - balance_ratio) * 3);
    else
        imbalance_penalty = 0;
    end
    
    if t >= 5
        recent_fairness = results.fairness(max(1, t-4):t);
        recent_fairness = recent_fairness(recent_fairness > 0);
        if ~isempty(recent_fairness) && length(recent_fairness) > 1
            fairness_variance = std(recent_fairness);
            stability_penalty = fairness_variance * 5;
        else
            stability_penalty = 0;
        end
    else
        stability_penalty = 0;
    end
    
    if t > 1 && results.fairness(t-1) > 0
        improvement = results.fairness(t) - results.fairness(t-1);
        improvement_bonus = improvement * 8;
    else
        improvement_bonus = 0;
    end
    
    high_fairness_bonus = 0;
    if results.fairness(t) > 0.9
        high_fairness_bonus = 5;
    elseif results.fairness(t) > 0.85
        high_fairness_bonus = 2;
    end
    
    reward = fairness_reward ...
             - handover_penalty ...
             + utilization_bonus ...
             + throughput_reward ...
             - imbalance_penalty ...
             - stability_penalty ...
             + improvement_bonus ...
             + high_fairness_bonus;
    
    reward = max(-5, min(35, reward));
end
