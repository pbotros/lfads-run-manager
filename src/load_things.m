% Identify the datasets you'll be using
dc = BmiExperiment.DatasetCollection('/Volumes/DATA_01/ELZ/VS265/');
ds = BmiExperiment.Dataset(dc, 'PacoBMI_days.mat', 'Day18'); % adds this dataset to the collection
dc.loadInfo; % loads dataset metadata

% Run a single model for each dataset, and one stitched run with all datasets
runRoot = '/Volumes/DATA_01/ELZ/VS265/generated';
rc = BmiExperiment.RunCollection(runRoot, '20181115-204953', dc);

% Setup hyperparameters, 4 sets with number of factors swept through 2,4,6,8
par = BmiExperiment.RunParams;
par.spikeBinMs = 100; % rebin the data at 100 ms
par.c_co_dim = 0; % no controller outputs --> no inputs to generator
par.c_batch_size = 15; % must be < 1/5 of the min trial count
par.c_gen_dim = 64; % number of units in generator RNN
par.c_ic_enc_dim = 64; % number of units in encoder RNN
par.c_learning_rate_stop = 1e-6; % we can stop really early for the demo
parSet = par.generateSweep('c_factors_dim', [2 4 6 8]);
rc.addParams(parSet);

runName = dc.datasets(1).getSingleRunName(); % == 'single_dataset001'
rc.addRunSpec(BmiExperiment.RunSpec(runName, dc, 1));

loaded_data = ds.loadData();

% spikes: nTrials x nChannels x nTime
spikes = loaded_data.spikes;
nChannels = 15;

% spike_rates_joined: nChannels x (nTime * nTrials)
spike_rates_joined = reshape(permute(spikes, [2, 3, 1]), nChannels, []);
num_runs = size(rc.runs, 2);

% Plot figure 1: Inferred Rates against Real Rates: all trials, all targets
figure;
hold on;
for run_idx = 1:num_runs
    run = rc.runs(run_idx);
    means = run.loadPosteriorMeans();
    
    % inferred_rates: nTrials x nChannels x nTime
    inferred_rates = permute(means.rates, [3, 1, 2]);
    
    % inferred_rates_joined: nChannels x (nTime * nTrials)
    inferred_rates_joined = reshape(permute(inferred_rates, [2, 3, 1]), nChannels, []);
    
    num_factors = run.params.c_factors_dim;
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

% Find the target with the most trials
all_targets = sort(unique(loaded_data.targets));
all_targets = all_targets(all_targets ~= 0);
num_trials_per_target = [];
for target_idx = 1:size(all_targets, 1)
    target = all_targets(target_idx);
    
    if target ~= 0
        num_trials_per_target(target_idx) = nnz(loaded_data.targets == target);
    else
        num_trials_per_target(target_idx) = 0;
    end
end

[~, chosen_target_idx] = max(num_trials_per_target);
chosen_target = all_targets(chosen_target_idx);

% Look at trials for the chosen target
trials_for_target = find(loaded_data.targets == chosen_target);
spikes_for_trials_for_target = spikes(trials_for_target, :, :);
channel_to_plot = 12;

figure;
ax1 = subplot(2, 1, 1);
title(ax1, sprintf('Single Trial, Channel %d, Real', channel_to_plot));
hold on;
% plot the real data first for this trial:
for trial_idx = 1:size(spikes_for_trials_for_target, 1)
    s = squeeze(spikes_for_trials_for_target(trial_idx, channel_to_plot, :));
    interp_t = linspace(1, size(s, 1), size(s, 1)*3);
    ss = spline(1:size(s, 1), s, interp_t);
    plot(ax1, interp_t, ss);
end

% and then plot inferred data for one of the runs overlaid
% try with 2 factors
run_idx = 1;
run = rc.runs(run_idx);
means = run.loadPosteriorMeans();

% inferred_rates: nTrials x nChannels x nTime
inferred_rates_for_trials_for_target = permute(means.rates(:, :, trials_for_target), [3, 1, 2]);

ax2 = subplot(2, 1, 2);
title(ax2, sprintf('Single Trial, Channel %d, LFADS', channel_to_plot));
hold on;
for trial_idx = 1:size(inferred_rates_for_trials_for_target, 1)
    s = squeeze(inferred_rates_for_trials_for_target(trial_idx, channel_to_plot, :));
    interp_t = linspace(1, size(s, 1), size(s, 1)*3);
    ss = spline(1:size(s, 1), s, interp_t);
    plot(ax2, interp_t, ss);
end
hold off;