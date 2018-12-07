% Identify the datasets you'll be using
dc = BmiExperiment.DatasetCollection('/Volumes/DATA_01/ELZ/VS265/');
params = struct;
params.shuffle = 0;
params.unit_type = 'direct';
ds = BmiExperiment.Dataset(dc, 'PacoBMI_days.mat', 'Day18', params); % adds this dataset to the collection
dc.loadInfo; % loads dataset metadata

% Run a single model for each dataset, and one stitched run with all datasets
runRoot = '/Volumes/DATA_01/ELZ/VS265/generated';
rc = BmiExperiment.RunCollection(runRoot, '20181121-141842', dc);
% rc = BmiExperiment.RunCollection(runRoot, '20181121-144111', dc);

% Setup hyperparameters, 4 sets with number of factors swept through 2,4,6,8
par = BmiExperiment.RunParams;
par.spikeBinMs = 100; % rebin the data at 100 ms
par.c_co_dim = 0; % no controller outputs --> no inputs to generator
par.c_batch_size = 15; % must be < 1/5 of the min trial count
par.c_gen_dim = 64; % number of units in generator RNN
par.c_ic_enc_dim = 64; % number of units in encoder RNN
par.c_learning_rate_stop = 1e-6; % we can stop really early for the demo
parSet = par.generateSweep('c_factors_dim', [2 4 6 8 10]);
rc.addParams(parSet);

runName = dc.datasets(1).getSingleRunName(); % == 'single_dataset001'
rc.addRunSpec(BmiExperiment.RunSpec(runName, dc, 1));

loaded_data = ds.loadData();

% spikes: nTrials x nChannels x nTime
spikes = loaded_data.spikes;
nChannels = size(spikes, 2);


% Random trial to plot factors and spike rates
trial_idx = 13;

% spike_rates_joined: nChannels x (nTime * nTrials)
spike_rates_joined = reshape(permute(spikes(trial_idx, :, :), [2, 3, 1]), nChannels, []);
num_runs = size(rc.runs, 2);

% Plot figure 1: Inferred Rates against Real Rates: all trials, all targets
figure;
hold on;

for run_idx = 1:num_runs
    run = rc.runs(run_idx);
    means = run.loadPosteriorMeans();
    
    % inferred_rates_joined: nChannels x (nTime * nTrials)
    inferred_rates_joined = reshape(means.rates(:, :, trial_idx), nChannels, []);
    
    num_factors = run.params.c_factors_dim;
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

channels_to_plot = [4, 8, 12];
channel_idx = 1;

figure;
for channel_to_plot = channels_to_plot
    ax1 = subplot(2, length(channels_to_plot), channel_idx);
    title(ax1, { ...
        sprintf('Single Trial, Target %d', chosen_target), ...
        sprintf('Channel %d, Real', channel_to_plot) ...
    });
    set(gca, 'ytick', []);
    set(gca, 'YColor','none');
    hold on;
    % plot the real data first for this trial:
    for trial_idx = 1:size(spikes_for_trials_for_target, 1)
        s = squeeze(spikes_for_trials_for_target(trial_idx, channel_to_plot, :));
        interp_t = linspace(1, size(s, 1), size(s, 1)*3);
        ss = spline(1:size(s, 1), s, interp_t);
        plot(ax1, interp_t, ss);
        ylim([0 inf]);
    end

    % and then plot inferred data for one of the runs overlaid
    % try with the most factors to see how it looks
    run_idx = num_runs;
    run = rc.runs(run_idx);
    means = run.loadPosteriorMeans();

    % inferred_rates: nTrials x nChannels x nTime
    inferred_rates_for_trials_for_target = permute(means.rates(:, :, trials_for_target), [3, 1, 2]);

    ax2 = subplot(2, length(channels_to_plot), length(channels_to_plot) + channel_idx);
    title(ax2, { ...
        sprintf('Single Trial, Target %d', chosen_target), ...
        sprintf('Channel %d, LFADS (%d factors)', channel_to_plot, run.params.c_factors_dim) ...
    });
    xlabel('Time (bins)');
    set(gca, 'ytick', []);
    set(gca, 'YColor','none');
    hold on;
    for trial_idx = 1:size(inferred_rates_for_trials_for_target, 1)
        s = squeeze(inferred_rates_for_trials_for_target(trial_idx, channel_to_plot, :));
        interp_t = linspace(1, size(s, 1), size(s, 1)*3);
        ss = spline(1:size(s, 1), s, interp_t);
        plot(ax2, interp_t, ss);
    end
    channel_idx = channel_idx + 1;
end
hold off;

% plot T-SNE for the run with the most factors, looks best
run_idx = num_runs;
run = rc.runs(run_idx);
means = run.loadPosteriorMeans();

% T-SNE on the initial conditions for generator units
tsned = tsne(means.generator_ics', 'Exaggeration', length(unique(loaded_data.targets)));

figure;
hold on;
gscatter(tsned(:, 1), tsned(:, 2), loaded_data.targets); 
title(sprintf('T-SNE, G0 (%d factors)', run.params.c_factors_dim));
legend off;
set(gca,'xtick',[]);
set(gca,'ytick',[]);
hold off;
