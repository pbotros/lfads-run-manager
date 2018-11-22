function [decoder] = build_decoder(inputs, trialIdxs)
% === INPUT PARAMETERS
% inputs: should be a matrix of size nTrials x nInputs x nTimeBins.
%         we will join together the inputs along trials & time bins
%
% === OUTPUT PARAMETERS
% decoder: decoder struct containing fit parameters and data used to fit.
%          Creates a decoder according to the equation:
%              Y = (decoder.A) * X + b
%          where X is a column vector of inputs at a single time (i.e. a
%          15x1 vector if there are 15 channels), and Y the column output
%          vector (i.e. a 2x1 vector if there are 2 outputs, (x, y)
%          velocities).
%
%   decoder.inputs: Input data (i.e. spike data) used as inputs to perform
%     the regression.
%   decoder.real_outputs: Cursor velocities used as "source of truth" for
%     performing the regression.
%
% USAGE:
%   loaded_data = dataset.loadData();
%   decoder = build_decoder(loaded_data.spikes, loaded_data.trialIdxs)

    load('/Volumes/DATA_01/ELZ/VS265/Paco_velocities.mat', 'velocity_cell');

    real_cursor_velocities = [];
    for trialIdx = 1:size(velocity_cell{18}, 1)
        if ismember(trialIdx, trialIdxs)

            velocity_datum = velocity_cell{18}{trialIdx}(1:10, :);
            real_cursor_velocities = [real_cursor_velocities; velocity_datum];
        end
    end

    num_outputs = size(real_cursor_velocities, 2);
    if num_outputs ~= 2
        throw(MException('Illegal outputs loaded', 'Only two outputs (x, y) supported.'));
    end

    inputs_flattened = [];
    for trialIdx = 1:size(inputs, 1)
        inputs_flattened = [inputs_flattened; squeeze(inputs(trialIdx, :, 1:10))'];
    end

    % NOTE: trying "single" linear regression on each velocity dimension,
    % but leaving multivariate regression setup here:
    %
    % If there are 15 channels and 2 output dimensions, X looks like:
    % [
    %  1, x1, ..., x15, 0, ..., 0, ...,   0;
    %  0, 0,  ...,   0, 1, x1, x2, ..., x15
    % ]
    % i.e. first 16 parameters of beta will be for x1 and second 16 for x2
    % X = cell(size(inputs_flattened, 1),1);
    % num_inputs = size(inputs_flattened, 2);
    % for i = 1:size(inputs_flattened, 1)
    %     X{i} = [1 inputs_flattened(i, :, :) zeros(1, num_inputs+1); ...
    %         zeros(1, num_inputs+1) 1 inputs_flattened(i, :, :)];
    % end
    % [beta, sigma, err] = mvregress(X, real_cursor_velocities, 'maxiter', 1000);

    % Per https://www.mathworks.com/help/stats/regress.html
    X_velocity_x = [ones(size(inputs_flattened, 1), 1) inputs_flattened];
    X_velocity_y = [ones(size(inputs_flattened, 1), 1) inputs_flattened];
    
    [b_x,~,r_x] = regress(real_cursor_velocities(:, 1), X_velocity_x);
    [b_y,~,r_y] = regress(real_cursor_velocities(:, 2), X_velocity_y);
    
    b = [b_x(1) b_y(1)];
    A = [b_x(2:end) b_y(2:end)];
    
    decoder = struct;
    decoder.A = A;
    decoder.b = b;
    decoder.err = [r_x r_y];
    decoder.inputs = inputs_flattened;
    decoder.real_outputs = real_cursor_velocities;

    % Plot l2 norms for each data point, and norm of the cursor velocities.
    % figure; histogram(vecnorm(real_cursor_velocities - (inputs_flattened * A' + b'), 2, 2));
    % figure; histogram(vecnorm(real_cursor_velocities, 2, 2));
    % figure; histogram(err);
    figure;
    hold on;
    histogram(decoder.err);
    histogram(vecnorm(decoder.real_outputs, 2, 2));
    legend('Regression Error', 'L2 Norm of Real Velocities');
    legend;
    hold off;
end

