function [decoder] = build_decoder(inputs, input_params)
% === INPUT PARAMETERS
% inputs: should be a cell array of size nTrials, with each cell nTimeBins x nInputs.
% input_params.skip_plots = 0 or 1, whether plots should be skipped
% input_params.velocity_delay: number of time steps to lag the velocity
% calculation from the spikes
% input_params.gaussian_window, number of time steps to use as a gaussian
%                               window for smoothing
% input_params.moving_average, number of time steps for a moving average
%
% === OUTPUT PARAMETERS
% decoder: decoder struct containing fit parameters and data used to fit.
%
%   decoder.inputs: Input data (i.e. spike data) used as inputs to perform
%     the regression.
%   decoder.real_outputs: Cursor velocities used as "source of truth" for
%     performing the regression.
%
% USAGE:
%   loaded_data = dataset.loadData();
%   decoder = build_decoder(loaded_data.raw_data);

    load('/Volumes/DATA_01/ELZ/VS265/Paco_velocities.mat', 'velocity_cell');

    % JMC 2003: "10 bins preceding a given point in time were used for
    % training the model and predicting with it"
    NUM_TIME_LAGS = 10;

    inputs_flattened = [];
    real_cursor_velocities = [];

    % The number of time bins that the velocity lags the spike rates. e.g.
    % a value of 1 means that the spikes during time t correspond to
    % velocity at time (t+1).
    if isfield(input_params, 'velocity_delay')
        velocity_delay = input_params.velocity_delay;
    else
        velocity_delay = 1;
    end
    day = 18;
    
    if isfield(input_params, 'gaussian_window')
        w = gausswin(input_params.gaussian_window);
        w = w/sum(w);
        filter_func = @(x) filter(w, 1, x);
    elseif isfield(input_params, 'moving_average')
        w = (1/input_params.moving_average)*ones(input_params.moving_average,1);
        filter_func = @(x) filter(w, 1, x);
    else
        filter_func = @(x) x;
    end
    
    for trialIdx = 1:size(velocity_cell{day}, 1) % 18 = day 18
        if size(velocity_cell{day}{trialIdx}, 1) < (NUM_TIME_LAGS+velocity_delay)
            continue
        end

        velocity_datum = velocity_cell{day}{trialIdx}((NUM_TIME_LAGS+velocity_delay):end, :);
        % Throw out any trials that had zero velocities
        if any(velocity_datum(:) == 0)
            continue;
        end

        real_cursor_velocities = [real_cursor_velocities; velocity_datum];
        % Try polar coordinates instead of x,y?
        % [theta, rho] = cart2pol(velocity_datum(:, 1), velocity_datum(:, 2));
        % real_cursor_velocities = [real_cursor_velocities; theta rho];

        num_time_bins = size(velocity_datum, 1);
        trial_inputs_with_lag = [];
        trial_inputs = inputs{trialIdx};
        % Append a copy of each trial's data, but time shifted appropriately
        for start_idx = 1:1:NUM_TIME_LAGS
            shifted = trial_inputs(start_idx:1:(start_idx + num_time_bins - 1), :);
            shifted = filter_func(shifted);
            trial_inputs_with_lag = [trial_inputs_with_lag shifted];
        end
        inputs_flattened = [inputs_flattened; trial_inputs_with_lag];
    end

    num_outputs = size(real_cursor_velocities, 2);
    if num_outputs ~= 2
        throw(MException('Illegal outputs loaded', 'Only two outputs (x, y) supported.'));
    end

    % Uncomment to override the output velocities to a system with a
    % known A, b. Should be zero error.
    % dummy_A = randn(150, 2);
    % dummy_b = randn(1, 2);
    % real_cursor_velocities = inputs_flattened * [dummy_b; dummy_A];

    decoder = struct;

%     ATTEMPT 1: Causal Weiner Filter (~ linear regression)
    title_str = 'Least Squares Estimation';
    inputs_flattened = [ones(size(inputs_flattened, 1), 1) inputs_flattened];
    % A = inv(X' X) X' Y
    Ab = (inputs_flattened' * inputs_flattened) \ inputs_flattened' * real_cursor_velocities;
    decoder.b = Ab(1, :);
    decoder.A = Ab(2:end, :);
    decoder.reconstructed = inputs_flattened * Ab;
    decoder.err = real_cursor_velocities - (inputs_flattened * Ab);

%     ATTEMPT 2: mvregress as independently as possible
%
%     If there are 15 channels and 2 output dimensions, X looks like:
%     [
%      1, x1, ..., x15, 0, ..., 0, ...,   0;
%      0, 0,  ...,   0, 1, x1, x2, ..., x15
%     ]
%     i.e. first 16 parameters of beta will be for x1 and second 16 for x2
%     title_str = 'mvregress - a';
%     X = cell(size(inputs_flattened, 1),1);
%     num_inputs = size(inputs_flattened, 2);
%     for i = 1:size(inputs_flattened, 1)
%         X{i} = [1 inputs_flattened(i, :, :) zeros(1, num_inputs+1); ...
%             zeros(1, num_inputs+1) 1 inputs_flattened(i, :, :)];
%     end
%     [beta, sigma, err] = mvregress(X, real_cursor_velocities, 'maxiter', 1000);
%     decoder.err = err;

%     ATTEMPT 2b: mvregress together
%
%     If there are 15 channels and 2 output dimensions, X looks like:
%     [
%      1, x1, ..., x15, 0, ...,   0;
%      1, 0,  ...,   0  x1, ..., x15
%     ]
%     i.e. separate slopes but same intercepts.
%     title_str = 'mvregress - b';
%     X = cell(size(inputs_flattened, 1),1);
%     num_inputs = size(inputs_flattened, 2);
%     for i = 1:size(inputs_flattened, 1)
%         X{i} = [1 inputs_flattened(i, :, :) zeros(1, num_inputs) ; ...
%             1 zeros(1, num_inputs) inputs_flattened(i, :, :)];
%     end
%     [beta, sigma, err] = mvregress(X, real_cursor_velocities, 'maxiter', 1000);
%     decoder.err = err;

%   ATTEMPT 3: linear regression via regress() on individual x, y
%     title_str = 'Linear regress';
%     X = [ones(size(inputs_flattened, 1), 1) inputs_flattened];
%     [b_x,~,r_x] = regress(real_cursor_velocities(:, 1), X);
%     [b_y,~,r_y] = regress(real_cursor_velocities(:, 2), X);
%     b = [b_x(1) b_y(1)];
%     A = [b_x(2:end) b_y(2:end)];
%     decoder.err = [r_x r_y];

    decoder.inputs = inputs_flattened;
    decoder.real_outputs = real_cursor_velocities;

    if ~isfield(input_params, 'skip_plots') || input_params.skip_plots == 0
        relative_err = abs(decoder.err ./ decoder.real_outputs);
        figure;
        ax1 = subplot(2, 1, 1);
        histogram(ax1, log10(relative_err(:, 1)), 100);
        title(title_str);
        set(ax1, 'YScale', 'log');
        legend('X: Relative Error (log10)');

        ax2 = subplot(2, 1, 2);
        histogram(ax2, log10(relative_err(:, 2)), 100);
        title(title_str);
        set(ax2, 'YScale', 'log');
        legend('Y: Relative Error (log10)');
        legend;
        hold off;
    end
    
end

