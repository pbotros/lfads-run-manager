if ~exist('lfads_results', 'var')
    lfads_results = load_lfads_results('20181121-141842');
end
if ~exist('lfads_results_shuffled', 'var')
    lfads_results_shuffled = load_lfads_results('20181207-111156');
end
if ~exist('lfads_results_day14', 'var')
    lfads_results_day14 = load_lfads_results('20181210-093230', 'Day14');
end

spikes = lfads_results.spikes;
nChannels = lfads_results.nChannels;

% ========================
% Plot real/inferred spike rates and factors across *all* trials
% ========================

% spike_rates_joined: nChannels x (nTime * nTrials)
spike_rates_joined = reshape(permute(spikes, [2, 3, 1]), nChannels, []);
num_runs = lfads_results.num_runs;

% Plot Inferred Rates against Real Rates: all trials, all targets
figure;
hold on;
for run_idx = 1:num_runs
    means = lfads_results.means_per_run(run_idx);

    % inferred_rates_joined: nChannels x (nTime * nTrials)
    inferred_rates_joined = reshape(means.rates, nChannels, []);

    num_factors = lfads_results.factors_per_run(run_idx);
    % factors: num_factors x nTime x nTrials
    factors = means.factors;
    factors_joined = reshape(factors, num_factors, []);

    ax1 = subplot(3, num_runs, run_idx);
    imagesc(ax1, inferred_rates_joined);
    title(ax1, sprintf('%d Factors: Inferred Rates', num_factors));

    ax2 = subplot(3, num_runs, run_idx + num_runs);
    imagesc(ax2, factors_joined);
    title(ax2, sprintf('%d Factors: Factors', num_factors));
end

ax3 = subplot(3, num_runs, [num_runs * 2 + 1, num_runs * 3]);
imagesc(ax3, spike_rates_joined);
title(ax3, 'Real Rates');
hold off;

% ========================
% Plot a *single* trial's factors and real & inferred spike rates
% ========================
% Arbitrary trial to plot factors and spike rates
trial_idx = 13;

% spike_rates_joined: nChannels x (nTime * nTrials)
spike_rates_joined = reshape(permute(spikes(trial_idx, :, :), [2, 3, 1]), nChannels, []);

figure;
hold on;

for run_idx = 1:num_runs
    means = lfads_results.means_per_run(run_idx);
    num_factors = lfads_results.factors_per_run(run_idx);
    
    % inferred_rates_joined: nChannels x (nTime * nTrials)
    inferred_rates_joined = reshape(means.rates(:, :, trial_idx), nChannels, []);
    
    % factors: num_factors x nTime x nTrials
    factors = means.factors(:, :, trial_idx);
    factors_joined = reshape(factors, num_factors, []);

    ax1 = subplot(3, num_runs, run_idx + num_runs);
    ax2 = subplot(3, num_runs, run_idx);

    imagesc(ax1, inferred_rates_joined);
    yticks(ax1, 1:15);
    title(ax1, ...
        {sprintf('%d Factors: Inferred Rates', num_factors), ...
        sprintf('(Trial %d)', trial_idx)});    
    
    imagesc(ax2, factors_joined);
    yticks(ax2, 1:num_factors);
    title(ax2, ...
        {sprintf('%d Factors: Factors', num_factors), ...
        sprintf('(Trial %d)', trial_idx)});
end

ax3 = subplot(3, num_runs, [num_runs * 2 + 1, num_runs * 3]);
imagesc(ax3, spike_rates_joined);
yticks(ax3, 1:15);
title(ax3, 'Real Rates');
xlabel('Time (bins)');
ylabel('Neuron');
hold off;

% ========================
% Plot all factors / spiking rates for a particular LFADS run with 10
% factors
% ========================
figure;
hold on;
run_idx = 5; 
means = lfads_results.means_per_run(run_idx);
num_factors = lfads_results.factors_per_run(run_idx);

    
% inferred_rates: nTrials x nChannels x nTime
inferred_rates = permute(means.rates, [3, 1, 2]);
    
% inferred_rates_joined: nChannels x (nTime * nTrials)
inferred_rates_joined = reshape(means.rates, nChannels, []);
    
% factors: num_factors x nTime x nTrials
factors = means.factors;
factors_joined = reshape(factors, num_factors, []);

ax1 = subplot(3, 1, 1);
imagesc(ax1, spike_rates_joined);
title(ax1, 'Real Rates');
colorbar

ax2 = subplot(3, 1, 2);
imagesc(ax2, factors_joined);
colorbar
title(ax2, sprintf('%d Factors: Factors', num_factors));

ax3 = subplot(3, 1, 3);
imagesc(ax3, inferred_rates_joined);
title(ax3, sprintf('%d Factors: Inferred Rates', num_factors));
colorbar

hold off;




% ========================
% Condition-averaged plots of smoothed spike patterns
% ========================

% Find the target with the most trials
all_targets = sort(unique(lfads_results.targets));
all_targets = all_targets(all_targets ~= 0);
num_trials_per_target = [];
for target_idx = 1:size(all_targets, 1)
    target = all_targets(target_idx);
    
    if target ~= 0
        num_trials_per_target(target_idx) = nnz(lfads_results.targets == target);
    else
        num_trials_per_target(target_idx) = 0;
    end
end

%% PLOT WITHIN CONDITION SPIKE RATES

% [~, chosen_target_idx] = max(num_trials_per_target);
% chosen_target = all_targets(chosen_target_idx);
chosen_target = 74;

% Look at trials for the chosen target
trials_for_target = find(lfads_results.targets == chosen_target);
% nTrials x nChannels x nTime
spikes_for_trials_for_target = spikes(trials_for_target, :, :);

channels_to_plot = [8, 12];
channel_idx = 1;

figure;
for channel_to_plot = channels_to_plot
    ax1 = subplot(3, length(channels_to_plot), channel_idx);
    set(ax1, 'fontsize', 16);
    title(ax1, { ...
        sprintf('Trials to Target %d', chosen_target), ...
        sprintf('Neuron %d, Real', channel_to_plot) ...
    });
    xlabel('Time (ms)');
    set(gca, 'xtick', [0, 5, 10]);
    set(gca, 'xticklabel', {'0', '500', '1000'})
    set(gca, 'ytick', []);
    set(gca, 'YColor','none');
    hold on;

    
    % plot the real data first for this trial:
    for trial_idx = 1:size(spikes_for_trials_for_target, 1)
        plot_spline(...
            squeeze(spikes_for_trials_for_target(trial_idx, channel_to_plot, :)), ...
            0.5);
    end
    
    mean_real = mean(squeeze(spikes_for_trials_for_target(:, channel_to_plot, :)))';
    std_real = std(squeeze(spikes_for_trials_for_target(:, channel_to_plot, :)))';
    
    disp(std_real'./mean_real');
    plot_spline(...
            mean_real, ...
            5.0, [0 0 0]);
    plot_spline(...
            mean_real + std_real, ...
            2.0, [0 0 0], '--');
    plot_spline(...
        mean_real - std_real, ...
        2.0, [0 0 0], '--');
    
    % and then plot inferred data for one of the runs overlaid
    % try with the most factors to see how it looks
    run_idx = num_runs;
    means = lfads_results.means_per_run(run_idx);
    num_factors = lfads_results.factors_per_run(run_idx);

    % inferred_rates: nTrials x nChannels x nTime
    inferred_rates_for_trials_for_target = permute(means.rates(:, :, trials_for_target), [3, 1, 2]);

    ax2 = subplot(3, length(channels_to_plot), length(channels_to_plot) + channel_idx);
    set(ax2, 'fontsize', 16);
    title(ax2, { ...
        sprintf('Trials to Target %d', chosen_target), ...
        sprintf('Neuron %d, LFADS (%d factors)', channel_to_plot, num_factors) ...
    });
    xlabel('Time (ms)');
    set(gca, 'xtick', [0, 5, 10]);
    set(gca, 'xticklabel', {'0', '500', '1000'})
    set(gca, 'ytick', []);
    set(gca, 'YColor','none');
    hold on;
    for trial_idx = 1:size(inferred_rates_for_trials_for_target, 1)
        plot_spline(...
            squeeze(inferred_rates_for_trials_for_target(trial_idx, channel_to_plot, :)), ...
            0.5);
    end
    mean_inferred = mean(squeeze(inferred_rates_for_trials_for_target(:, channel_to_plot, :)))';
    std_inferred = std(squeeze(inferred_rates_for_trials_for_target(:, channel_to_plot, :)))';
    plot_spline(...
        mean_inferred, ...
        5.0, [0 0 0]);
    plot_spline(...
        mean_inferred + std_inferred, ...
        2.0, [0 0 0], '--');
    plot_spline(...
        mean_inferred - std_inferred, ...
        2.0, [0 0 0], '--');
    
    ax3 = subplot(3, length(channels_to_plot), 2 * length(channels_to_plot) + channel_idx);
    bar(1:10, [std_real./mean_real, std_inferred./mean_inferred]);
    title(ax3, { ...
        'Coefficient of Variation', ...
        sprintf('Day 18, Neuron %d', channel_to_plot) ...
    });
    xlabel('Time (ms)');
    ylabel('CV');
    set(gca, 'FontSize', 16);
    set(gca, 'xtick', [0, 5, 10]);
    set(gca, 'xticklabel', {'0', '500', '1000'})
    legend('Real', 'Inferred');
    channel_idx = channel_idx + 1;
end
hold off;

%% Find means and compare across neurons, days

% nTrials x nChannels x nTime => nChannels (2) x nTimeBins
mean_spikes_real_day18 = squeeze(mean(spikes_for_trials_for_target(:, channels_to_plot, :), 1));
mean_spikes_inferred_day18 = squeeze(mean(inferred_rates_for_trials_for_target(:, channels_to_plot, :), 1));

% nTrials x nChannels x nTime
spikes_for_trials_for_target_day14 = spikes(lfads_results_day14.targets == chosen_target, :, :);
mean_spikes_real_day14 = squeeze(mean(spikes_for_trials_for_target_day14(:, channels_to_plot, :), 1));

means_day14 = lfads_results_day14.means_per_run(num_runs);
inferred_rates_for_trials_for_target_14 = permute(...
    means_day14.rates(channels_to_plot, :, lfads_results_day14.targets == chosen_target), ...
    [3, 1, 2]);
mean_spikes_inferred_day14 = squeeze(mean(inferred_rates_for_trials_for_target_14, 1));

figure;
% subplot(2, 1, 1);
title('Inferred Spiking Rates Across Days');
hold on;
plot(1:10, mean_spikes_inferred_day18(1, :), 'r-');
plot(1:10, mean_spikes_inferred_day14(1, :), 'r--');
plot(1:10, mean_spikes_inferred_day18(2, :), 'b-');
plot(1:10, mean_spikes_inferred_day14(2, :), 'b--');
xlabel('Time (ms)');
ylabel('Spike Rates');
set(gca, 'ytick', []);
set(gca, 'YColor','none');
set(gca, 'xtick', [0, 5, 10]);
set(gca, 'xticklabel', {'0', '500', '1000'});
legend('Day18: Neuron 8, Target 74', 'Day14: Neuron 8, Target 74', ...
    'Day18: Neuron 12, Target 74', 'Day14: Neuron 12, Target 74');
set(gca, 'fontsize', 16);

% subplot(2, 1, 2);
% title('Real');
% hold on;
% plot(1:10, mean_spikes_real_day18(1, :), 'r-');
% plot(1:10, mean_spikes_real_day14(1, :), 'r--');
% plot(1:10, mean_spikes_real_day18(2, :), 'b-');
% plot(1:10, mean_spikes_real_day14(2, :), 'b--');
% xlabel('Time (ms)');
% ylabel('Spike Rates - µ');
% set(gca, 'xtick', [0, 5, 10]);
% set(gca, 'xticklabel', {'0', '500', '1000'})
% legend('Day18: Neuron 8, Target 74', 'Day14: Neuron 8, Target 74', ...
%     'Day18: Neuron 12, Target 74', 'Day14: Neuron 12, Target 74');

% For single channel, let's say channel 12, compare each target across days
% for correlation
inferred_spikes_day18 = lfads_results.means_per_run(num_runs).rates;
inferred_spikes_day14 = lfads_results_day14.means_per_run(num_runs).rates;
targets = sort(unique(lfads_results_day14.targets));
num_targets = length(targets);
xcorrs = zeros(num_targets, num_targets);
i = 1;
for target1 = sort(unique(lfads_results_day14.targets))'
    j = 1;
    for target2 = sort(unique(lfads_results_day14.targets))'
        mean_spikes_inferred_day18 = ...
            squeeze(mean(inferred_spikes_day18(12, :, lfads_results.targets == target1), 3));
        mean_spikes_inferred_day14 = ...
            squeeze(mean(inferred_spikes_day14(12, :, lfads_results_day14.targets == target2), 3));

        xcorrs(i, j) = xcorr(mean_spikes_inferred_day14, mean_spikes_inferred_day18, 0, 'coeff');
        j = j + 1;
    end
    i = i + 1;
end
figure;
% xticklabels(targets);
% yticklabels(targets);
imagesc(xcorrs);
colorbar;
title('Cross Correlation of Trajectories Across Targets');
set(gca, 'fontsize', 16);
set(gca, 'XTickLabel', 1:8);
set(gca, 'YTickLabel', 1:8);
xlabel('Target, Day 18');
ylabel('Target, Day 14');

% 200 trials. Which trials correlate highest with one another?
% 200x200 trials. One's to the same target should correlate highest.
hold off;

%%


% RC SHUFFLED

figure;
channel_idx = 1;
for channel_to_plot = channels_to_plot
    % and then plot inferred data for one of the runs overlaid
    % try with the most factors to see how it looks
    run_idx = num_runs;
    means = lfads_results.means_per_run(run_idx);
    num_factors = lfads_results.factors_per_run(run_idx);


    % inferred_rates: nTrials x nChannels x nTime
    inferred_rates_for_trials_for_target = permute(means.rates(:, :, trials_for_target), [3, 1, 2]);

    ax1 = subplot(2, length(channels_to_plot), channel_idx);
    set(ax1, 'fontsize', 16);
    title(ax1, { ...
        sprintf('Spike Rates, Target %d', chosen_target), ...
        sprintf('Neuron %d, LFADS (%d factors)', channel_to_plot, num_factors) ...
    });
    xlabel('Time (ms)');
    set(ax1, 'xtick', [0, 5, 10]);
    set(ax1, 'xticklabel', {'0', '500', '1000'})
    set(gca, 'ytick', []);
    set(gca, 'YColor','none');
    hold on;
    for trial_idx = 1:size(inferred_rates_for_trials_for_target, 1)
        s = squeeze(inferred_rates_for_trials_for_target(trial_idx, channel_to_plot, :));
        interp_t = linspace(1, size(s, 1), size(s, 1)*3);
        ss = spline(1:size(s, 1), s, interp_t);
        plot(ax1, interp_t, ss, 'LineWidth', 2);
    end
    
    
    % SHUFFLED rates
    means = lfads_results_shuffled.means_per_run(run_idx);

    % inferred_rates: nTrials x nChannels x nTime
    inferred_rates_for_trials_for_target = permute(means.rates(:, :, trials_for_target), [3, 1, 2]);

    ax2 = subplot(2, length(channels_to_plot), length(channels_to_plot) + channel_idx);
    set(ax2, 'fontsize', 16);
    title(ax2, { ...
        sprintf('Shuffled Spike Rates, Target %d', chosen_target), ...
        sprintf('Neuron %d, LFADS (%d factors)', channel_to_plot, lfads_results.factors_per_run(run_idx)) ...
    });
    xlabel('Time (ms)');
    set(gca, 'ytick', []);
    set(ax2, 'xtick', [0, 5, 10]);
    set(ax2, 'xticklabel', {'0', '500', '1000'})
    set(gca, 'YColor','none');
    hold on;
    for trial_idx = 1:size(inferred_rates_for_trials_for_target, 1)
        s = squeeze(inferred_rates_for_trials_for_target(trial_idx, channel_to_plot, :));
        interp_t = linspace(1, size(s, 1), size(s, 1)*3);
        ss = spline(1:size(s, 1), s, interp_t);
        plot(ax2, interp_t, ss, 'LineWidth', 2);
    end

    channel_idx = channel_idx + 1;
end
hold off;

%% K-MEANS
% plot T-SNE for the run with the most factors, looks best
run_idx = num_runs;
means = lfads_results.means_per_run(run_idx);


% T-SNE on the initial conditions for generator units
ics = means.generator_ics;

num_targets = length(unique(lfads_results.targets));


% is there a rotation of actual_clusters that matches best?
best_distance_from_actual = [];
best_best_value = Inf;

for i = 1:100
    clustered = kmeans(ics', num_targets, 'Start', 'uniform', 'OnlinePhase','on', 'MaxIter', 1000);

    distance_from_actual = [];
    for rotation_idx = 0:(num_targets - 1)
        actual_clusters = mod((lfads_results.targets - 73 + rotation_idx), 8) + 1;
        distance_from_actual(end + 1, :) = mod(abs(clustered - actual_clusters), 5);
    end
    [best_value, best_rotation] = min(sum(distance_from_actual, 2));
    if best_value < best_best_value || isempty(best_distance_from_actual)
        best_best_value = best_value;
        best_distance_from_actual = distance_from_actual(best_rotation, :);
    end
end

figure;
num_trials = length(distance_from_actual(best_rotation, :));
histogram(distance_from_actual(best_rotation, :));
hold on;
z = zeros(num_trials, 1);
histogram(...
    [zeros(floor(num_trials/8), 1); ...
    zeros(floor(num_trials/4), 1)+1; ...
    zeros(floor(num_trials/4), 1)+2; ...
    zeros(floor(num_trials/4), 1)+3; ...
    zeros(num_trials - floor(7*num_trials/8), 1)+4], ...
    'FaceAlpha', 0.1);
title('# Correct Predictions from K-Means Clustering on IC');
ylabel('# Correct');
xlabel('|Prediction - Actual|');
set(gca, 'XTickLabels', 0:4);
set(gca, 'FontSize', 16);
set(gca, 'XTick', 0:4);
legend('Actual', 'Chance');


%% ========================
% T-SNE
% ========================

% plot T-SNE for the run with the most factors, looks best
run_idx = num_runs;
means = lfads_results.means_per_run(run_idx);
num_factors = lfads_results.factors_per_run(run_idx);


% T-SNE on the initial conditions for generator units
tsned = tsne(means.generator_ics', 'Exaggeration', length(unique(lfads_results.targets)));

figure;
cmap = jet(8);
hold on;
gscatter(tsned(:, 1), tsned(:, 2), lfads_results.targets, cmap, '.', 40);
title(sprintf('T-SNE, G0 (%d factors)', num_factors), 'FontSize', 20);
legend({'1', '2', '3', '4', '5', '6', '7', '8'});
set(gca,'xtick',[]);
set(gca,'ytick',[]);
hold off;

% =========
% Plot negative log likelihood on the VAEs between shuffled and normal
% =========

figure;
bar(1:num_runs, ...
    [lfads_results.nll_bound_vaes; lfads_results_shuffled.nll_bound_vaes]');
legend('Unshuffled', 'Shuffled');
xticklabels({'2', '4', '6', '8', '10'});
xlabel('# Factors');
ylabel('NLL');
set(gca, 'FontSize', 16);
title('NLL Comparison Against Shuffled Data');



function plot_spline(s, line_width, color, linespec)
    interp_t = linspace(1, size(s, 1), size(s, 1)*3);
    ss = spline(1:size(s, 1), s, interp_t);
    if exist('color', 'var')
        if exist('linespec', 'var')
            plot(interp_t, ss, linespec, 'LineWidth', line_width, 'Color', color);
        else
            plot(interp_t, ss, 'LineWidth', line_width, 'Color', color);
        end
    else
        plot(interp_t, ss, 'LineWidth', line_width);
    end
    ylim([0 inf]);
end