function reward = calculate_reward(results, t)
    if t == 1 || results.fairness(t) == 0
        reward = 0;
        return;
    end
    
    fairness_reward = results.fairness(t) * 30;
    
    handover_penalty = results.handovers(t) * 0.15;
    
    throughput_reward = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = results.avg_allocation(t);
        throughput_reward = min(15, avg_throughput * 1.5);
    end
    
    high_fairness_bonus = 0;
    if results.fairness(t) > 0.95
        high_fairness_bonus = 10;
    elseif results.fairness(t) > 0.90
        high_fairness_bonus = 5;
    end
    
    reward = fairness_reward ...
             - handover_penalty ...
             + throughput_reward ...
             + high_fairness_bonus;
    
    reward = max(-5, min(60, reward));
end
