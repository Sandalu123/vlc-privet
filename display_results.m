load('output/data/comparison_results.mat');

fprintf('=== Analysis of Results ===\n');
fprintf('Metric          | WWA (Baseline) | RL-Enhanced    | Improvement\n');
fprintf('----------------|----------------|----------------|------------\n');

wwa_fair = mean(comparison.wwa.fairness);
rl_fair = mean(comparison.rl.fairness);
imp_fair = (rl_fair - wwa_fair) / wwa_fair * 100;
fprintf('Fairness        | %.4f         | %.4f         | %+.2f%%\n', wwa_fair, rl_fair, imp_fair);

wwa_tput = mean(comparison.wwa.throughput);
rl_tput = mean(comparison.rl.throughput);
imp_tput = (rl_tput - wwa_tput) / wwa_tput * 100;
fprintf('Throughput      | %.2f Mbps    | %.2f Mbps    | %+.2f%%\n', wwa_tput, rl_tput, imp_tput);

wwa_ho = mean(comparison.wwa.handovers);
rl_ho = mean(comparison.rl.handovers);
imp_ho = (rl_ho - wwa_ho) / wwa_ho * 100;
fprintf('Avg Handovers   | %.2f           | %.2f           | %+.2f%%\n', wwa_ho, rl_ho, imp_ho);

fprintf('\nDetailed Stats (Mean ± Std):\n');
fprintf('WWA Fairness: %.4f ± %.4f\n', mean(comparison.wwa.fairness), std(comparison.wwa.fairness));
fprintf('RL  Fairness: %.4f ± %.4f\n', mean(comparison.rl.fairness), std(comparison.rl.fairness));
fprintf('WWA Handovers: %.2f ± %.2f\n', mean(comparison.wwa.handovers), std(comparison.wwa.handovers));
fprintf('RL  Handovers: %.2f ± %.2f\n', mean(comparison.rl.handovers), std(comparison.rl.handovers));
