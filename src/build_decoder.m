function [decoder] = build_decoder(inputs)
% === INPUT PARAMETERS
% inputs: should be a cell array of size nTrials, with each cell nTimeBins x nInputs.
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
    % First time lag to use on data. Positive M indicates using past data;
    % e.g. M = 0 means to use times t - 0, t - 1, ..., t - 9.
    M = 0;

    time_lags = M:1:(M+NUM_TIME_LAGS-1);
    num_time_lags = size(time_lags, 2);

    inputs_flattened = [];
    real_cursor_velocities = [];
    % trialsAdded = 0;
    for trialIdx = 1:size(velocity_cell{18}, 1) % 18 = day 18
        velocity_datum = velocity_cell{18}{trialIdx};
        real_cursor_velocities = [real_cursor_velocities; velocity_datum];

        trial_inputs_with_lag = [];
        trial_inputs = inputs{trialIdx};
        % Append a copy of each trial's data, but time shifted appropriately
        for time_lag_idx = 1:num_time_lags
            time_lag = time_lags(time_lag_idx);
            shifted = circshift(trial_inputs, time_lag, 1);
            if time_lag > 0
                % A time lag that's positive means we shift "in" the past, so
                % zero out the first <time lag> rows
                if size(shifted, 1) <= time_lag
                    % zero out everything if this trial is too short
                    shifted = zeros(size(shifted));
                else
                    to_zero = shifted(1:time_lag, :);
                    shifted(1:time_lag, :) = zeros(size(to_zero));
                end
            elseif time_lag < 0
                % A time lag that's negative means we shift "out" the past, so
                % zero out the last <time lag> rows
                to_zero = shifted((end + time_lag + 1):end, :);
                shifted((end + time_lag + 1):end, :) = zeros(size(to_zero));
            end
            trial_inputs_with_lag = [trial_inputs_with_lag shifted];
        end
        inputs_flattened = [inputs_flattened; ...
            ones(size(trial_inputs_with_lag, 1), 1) trial_inputs_with_lag];
    end

    num_outputs = size(real_cursor_velocities, 2);
    if num_outputs ~= 2
        throw(MException('Illegal outputs loaded', 'Only two outputs (x, y) supported.'));
    end

    % Trim out time indexes that are at 0 velocity.
    % NOTE: commented out since with time lags, it doesn't make too much
    % sense to throw out 0 velocities
    %
    % nonzero_indices = any(sign(real_cursor_velocities), 2);
    % real_cursor_velocities = real_cursor_velocities(nonzero_indices, :);
    % inputs_flattened = inputs_flattened(nonzero_indices, :);

    % Least linear squares estimation (see JMC 2003)
    Ab = (inputs_flattened' * inputs_flattened) \ inputs_flattened' * real_cursor_velocities;

    % NOTE: trying "single" linear regression on each velocity dimension,
    % but leaving multivariate regression setup here:
    %
    % If there are 15 channels and 2 output dimensions, X looks like:
    % [
    %  1, x1, ..., x15, 0, ..., 0, ...,   0;
    %  0, 0,  ...,   0, 1, x1, x2, ..., x15
    % ]
    % i.e. first 16 parameters of beta will be for x1 and second 16 for x2
%     X = cell(size(inputs_repeated, 1),1);
%     num_inputs = size(inputs_repeated, 2);
%     for i = 1:size(inputs_repeated, 1)
%         X{i} = [1 inputs_repeated(i, :, :) zeros(1, num_inputs+1); ...
%             zeros(1, num_inputs+1) 1 inputs_repeated(i, :, :)];
%     end
%     [beta, sigma, err] = mvregress(X, real_cursor_velocities, 'maxiter', 1000);
%     decoder.err = err;

%
%     X = [ones(size(inputs_repeated, 1), 1) inputs_repeated];
%     [b_x,~,r_x] = regress(real_cursor_velocities(:, 1), X);
%     [b_y,~,r_y] = regress(real_cursor_velocities(:, 2), X);
%     b = [b_x(1) b_y(1)];
%     A = [b_x(2:end) b_y(2:end)];
%     decoder.err = [r_x r_y];

    decoder = struct;
    decoder.b = Ab(1, :);
    decoder.A = Ab(2:end, :);
    decoder.err = real_cursor_velocities - (inputs_flattened * Ab);
    decoder.inputs = inputs_flattened;
    decoder.real_outputs = real_cursor_velocities;


%     figure;
%     ax1 = subplot(2, 1, 1);
%     hold on;
%     histogram(ax1, decoder.err(:, 1), 100);
%     histogram(ax1, decoder.real_outputs(:, 1), 100);
%     legend('X: Residual', 'X: Real Velocity');
% 
%     ax2 = subplot(2, 1, 2);
%     hold on;
%     histogram(ax2, decoder.err(:, 2), 100);
%     histogram(ax2, decoder.real_outputs(:, 2), 100);
%     legend('Y: Residual', 'Y: Real Velocity');
%     legend;
%     hold off;
end

