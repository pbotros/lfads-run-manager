function s = load_kg_data()
    % Maybe the first day of MC
    load('~/Desktop/KG_MAT/PACO DATA/paco071508a.mat');
    addpath('~/Desktop/KG_MAT');
    % There's two bin_all_data's that are different; run this one
    run('~/Desktop/KG_MAT/bin_all_data.m');

    % This block filters neurons only used on that day
    p ='~/Desktop/KG_MAT/BMI_model_data/';
    a='Paco_prediction_15-Jul-2008_1.mat';
    load([p a]);
    N=sort(N);
    N_FIXED=N;
    p = '~/Desktop/KG_MAT/';
    path(path,p);
    % neuron_label=make_chan_labels(N);
    [r_i,r_c] =intersect(N_index,N_FIXED); %N_index is created by bin_data
    neurons_used = r_c;

    % use all neurons
%     neurons_used = reshape(1:size(N_index, 2), [], 1);

    %training
    lags=10;
    n_points_train = 6000 + 10; %6010; %10 min of data at 10hz + 1sec for the lags
    train=lags:n_points_train-1;
    test_length = size(spike_times, 1) - n_points_train; %i.e. number/100 give seconds of prediction
    test=length(train)+1:length(train)+1+test_length;

    %this is Y in the lin-pred actual data; data (shoulder pos,e pos, s vel, e vel)
    [ahat, mu, R2_fit, yhat_fit, Xused, var_ahat, t_ahat] = linmodel(Y,spike_times(:, neurons_used),lags,[],train);

    [R2_pred, yhat_pred] = linpred(Y,spike_times (:, neurons_used),ahat,mu,Xused,test);
    
    s = struct;
    % Number of time lags used.
    s.lags = lags;
    % channels_used reference the channel indices that were used to compute
    % this linear fit.
    s.channels_used = neurons_used;
    % This is the "A" matrix. Size 4 x (lags * length(channels_used)). This
    % transforms spikes into joint angles.
    % The four rows, in order, are:
    % 1. Angular position, shoulder
    % 2. Angular position, elbow
    % 3. Angular velocity, shoulder
    % 4. Angular velocity, elbow
    % The columns are in channel order, then chronological order. If channels_used
    % was [<1>, <2>, <3>, <4>] and there were 3 lags, then the 12 columns are:
    % [   <1> + 0, <2> + 0, <3> + 0, <4> + 0, ...
    %     <1> + 1, <2> + 1, <3> + 1, <4> + 1, ...
    %     <1> + 2, <2> + 2, <3> + 2, <4> + 2
    % ]
    % When using ahat, data must be organized this way.
    s.ahat = ahat;
    % Same ordering in rows as ahat.
    s.mu = mu;
    s.R2_prediction = R2_pred;
    
    s.joint_params_train = Y(train, :);
    s.joint_params_test = Y(test, :);
    % Use joint_to_cursor.m to go from predicted joint parameters to hand
    % position and velocity
end