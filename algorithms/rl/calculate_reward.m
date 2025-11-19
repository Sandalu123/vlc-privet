function reward = calculate_reward(results, t)
    if t == 1 || results.fairness(t) == 0
        reward = 0;
        return;
    end
    
    fairness_reward = results.fairness(t) * 40;
    
    handover_penalty = results.handovers(t) * 50.0;
    
    throughput_reward = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = results.avg_allocation(t);
        throughput_reward = avg_throughput * 4.0;
    end
    
    high_fairness_bonus = 0;
    if results.fairness(t) > 0.95
        high_fairness_bonus = 15;
    elseif results.fairness(t) > 0.92
        high_fairness_bonus = 8;
    end
    
    high_throughput_bonus = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = results.avg_allocation(t);
        if avg_throughput > 15.0
            high_throughput_bonus = 40;
        elseif avg_throughput > 12.0
            high_throughput_bonus = 25;
        elseif avg_throughput > 10.0
            high_throughput_bonus = 10;
        end
    end
    
    low_handover_bonus = 0;
    handover_rate = results.handovers(t) / max(results.total_users(t), 1);
    if handover_rate < 0.10
        low_handover_bonus = 100;
    elseif handover_rate < 0.20
        low_handover_bonus = 50;
    end
    
    reward = fairness_reward ...
             - handover_penalty ...
             + throughput_reward ...
             + high_fairness_bonus ...
             + high_throughput_bonus ...
             + low_handover_bonus;
    
    reward = max(-200, min(400, reward));
end
