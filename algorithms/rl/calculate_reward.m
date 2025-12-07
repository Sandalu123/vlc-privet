function reward = calculate_reward(results, t)
    if t == 1 || results.fairness(t) == 0
        reward = 0;
        return;
    end
    
    % Combined Fairness (Downlink + Uplink)
    avg_fairness = (results.fairness(t) + results.fairness_ul(t)) / 2;
    fairness_reward = avg_fairness * 45;
    
    % Increased penalty as per user request
    handover_penalty = results.handovers(t) * 50.0;
    
    throughput_reward = 0;
    if results.total_users(t) > 0 && t > 1
        % Combined Throughput
        avg_throughput = (results.avg_allocation(t) + results.avg_allocation_ul(t)) / 2;
        throughput_reward = avg_throughput * 6.0;
    end
    
    high_fairness_bonus = 0;
    if avg_fairness > 0.95
        high_fairness_bonus = 15;
    elseif avg_fairness > 0.92
        high_fairness_bonus = 8;
    end
    
    high_throughput_bonus = 0;
    if results.total_users(t) > 0 && t > 1
        avg_throughput = (results.avg_allocation(t) + results.avg_allocation_ul(t)) / 2;
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
        low_handover_bonus = 60;
    elseif handover_rate < 0.20
        low_handover_bonus = 30;
    end
    
    reward = fairness_reward ...
             - handover_penalty ...
             + throughput_reward ...
             + high_fairness_bonus ...
             + high_throughput_bonus ...
             + low_handover_bonus;
    
    reward = max(-200, min(400, reward));
end
