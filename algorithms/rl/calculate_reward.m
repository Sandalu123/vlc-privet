function reward = calculate_reward(results, t)
    if t == 1 || results.fairness(t) == 0
        reward = 0;
        return;
    end
    
    fairness_reward = results.fairness(t) * 18;
    
    handover_penalty = results.handovers(t) * 0.20;
    
    throughput_reward = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = results.avg_allocation(t);
        throughput_reward = min(35, avg_throughput * 4.2);
    end
    
    high_fairness_bonus = 0;
    if results.fairness(t) > 0.94
        high_fairness_bonus = 8;
    elseif results.fairness(t) > 0.90
        high_fairness_bonus = 5;
    elseif results.fairness(t) > 0.85
        high_fairness_bonus = 2;
    end
    
    high_throughput_bonus = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = results.avg_allocation(t);
        if avg_throughput > 6.0
            high_throughput_bonus = 12;
        elseif avg_throughput > 5.0
            high_throughput_bonus = 7;
        elseif avg_throughput > 4.0
            high_throughput_bonus = 3;
        end
    end
    
    low_handover_bonus = 0;
    handover_rate = results.handovers(t) / max(results.total_users(t), 1);
    if handover_rate < 0.3
        low_handover_bonus = 5;
    elseif handover_rate < 0.4
        low_handover_bonus = 2;
    end
    
    reward = fairness_reward ...
             - handover_penalty ...
             + throughput_reward ...
             + high_fairness_bonus ...
             + high_throughput_bonus ...
             + low_handover_bonus;
    
    reward = max(-5, min(75, reward));
end
