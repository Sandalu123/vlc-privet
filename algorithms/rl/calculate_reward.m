function reward = calculate_reward(results, t)
    if t == 1 || results.fairness(t) == 0
        reward = 0;
        return;
    end
    
    fairness_reward = results.fairness(t) * 12;
    
    handover_penalty = results.handovers(t) * 0.12;
    
    throughput_reward = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = results.avg_allocation(t);
        throughput_reward = min(40, avg_throughput * 5.5);
    end
    
    high_fairness_bonus = 0;
    if results.fairness(t) > 0.92
        high_fairness_bonus = 5;
    elseif results.fairness(t) > 0.88
        high_fairness_bonus = 2;
    end
    
    high_throughput_bonus = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = results.avg_allocation(t);
        if avg_throughput > 6.5
            high_throughput_bonus = 15;
        elseif avg_throughput > 5.5
            high_throughput_bonus = 8;
        elseif avg_throughput > 4.5
            high_throughput_bonus = 4;
        end
    end
    
    reward = fairness_reward ...
             - handover_penalty ...
             + throughput_reward ...
             + high_fairness_bonus ...
             + high_throughput_bonus;
    
    reward = max(-5, min(80, reward));
end
