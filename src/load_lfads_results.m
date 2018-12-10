function lfads_results = load_lfads_results(run_name, day)
    if ~exist('day', 'var')
        day = 'Day18';
    end
    % Identify the datasets you'll be using
    dc = BmiExperiment.DatasetCollection('/Volumes/DATA_01/ELZ/VS265/');
    params = struct;
    params.shuffle = 0;
    params.unit_type = 'direct';
    ds = BmiExperiment.Dataset(dc, 'PacoBMI_days.mat', day, params); % adds this dataset to the collection
    dc.loadInfo; % loads dataset metadata

    % Run a single model for each dataset, and one stitched run with all datasets
    runRoot = '/Volumes/DATA_01/ELZ/VS265/generated';
    rc = BmiExperiment.RunCollection(runRoot, run_name, dc);
    % rc = BmiExperiment.RunCollection(runRoot, '20181121-144111', dc);

    % shuffled data, direct
    % rc = BmiExperiment.RunCollection(runRoot, '20181207-111156', dc);

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
    
    lfads_results = struct;
    lfads_results.spikes = spikes;
    lfads_results.nChannels = nChannels;
    lfads_results.factors_per_run = arrayfun(@(run) run.params.c_factors_dim, rc.runs());
    lfads_results.means_per_run = arrayfun(@(run) run.loadPosteriorMeans(), rc.runs());
    lfads_results.num_runs = size(rc.runs, 2);
    lfads_results.targets = loaded_data.targets;
    lfads_results.nll_bound_vaes = arrayfun(...
        @(means) sum(means.nll_bound_vaes), lfads_results.means_per_run);
end