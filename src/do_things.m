% Identify the datasets you'll be using
dc = BmiExperiment.DatasetCollection('/Volumes/DATA_01/ELZ/VS265/');
ds = BmiExperiment.Dataset(dc, 'PacoBMI_days.mat', 'Day01'); % adds this dataset to the collection
dc.loadInfo; % loads dataset metadata

% Run a single model for each dataset, and one stitched run with all datasets
runRoot = '/Volumes/DATA_01/ELZ/VS265/generated';
rc = BmiExperiment.RunCollection(runRoot, 'latest', dc);

% Setup hyperparameters, 4 sets with number of factors swept through 2,4,6,8
par = BmiExperiment.RunParams;
par.spikeBinMs = 100; % rebin the data at 100 ms
par.c_co_dim = 0; % no controller outputs --> no inputs to generator
par.c_batch_size = 15; % must be < 1/5 of the min trial count
par.c_gen_dim = 64; % number of units in generator RNN
par.c_ic_enc_dim = 64; % number of units in encoder RNN
par.c_learning_rate_stop = 1e-3; % we can stop really early for the demo
parSet = par.generateSweep('c_factors_dim', [2 4 6 8]);
rc.addParams(parSet);

% Setup which datasets are included in each run, here just the one
runName = dc.datasets(1).getSingleRunName(); % == 'single_dataset001'
rc.addRunSpec(BmiExperiment.RunSpec(runName, dc, 1));

% Generate files needed for LFADS input on disk
rc.prepareForLFADS();

% Write a python script that will train all of the LFADS runs using a
% load-balancer against the available CPUs and GPUs
rc.writeShellScriptRunQueue('display', 0, 'python_version', 3);
