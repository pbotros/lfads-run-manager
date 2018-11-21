function [A, b] = build_decoder(inputs, trialIdxs)
% inputs: should be a matrix of size nTrials x nInputs x nTimeBins.
%         we will join together the inputs along trials & time bins
    load('/Volumes/DATA_01/ELZ/VS265/Paco_velocities.mat', 'velocity_cell');
    
    real_cursor_velocities = [];
    for trialIdx = 1:size(velocity_cell{18}, 1)
        if ismember(trialIdx, trialIdxs)
            real_cursor_velocities = [real_cursor_velocities; velocity_cell{18}{trialIdx}(1:10, :)];
        end
    end

    num_outputs = size(real_cursor_velocities, 2);
    if num_outputs ~= 2
        throw(MException('Illegal outputs loaded', 'Only two outputs (x, y) supported.'));
    end

    inputs_flattened = [];
    for trialIdx = 1:size(inputs, 1)
        inputs_flattened = [inputs_flattened; squeeze(inputs(trialIdx, :, :))'];
    end

    % If there are 15 channels and 2 output dimensions, X looks like:
    % [
    %  1, x1, ..., x15, 0, ..., 0, ...,   0;
    %  0, 0,  ...,   0, 1, x1, x2, ..., x15
    % ]
    % i.e. first 16 parameters of beta will be for x1 and second 16 for x2
    X = cell(size(inputs_flattened, 1),1);
    num_inputs = size(inputs_flattened, 2);
    for i = 1:size(inputs_flattened, 1)
        X{i} = [1 inputs_flattened(i, :, :) zeros(1, num_inputs+1); ...
            zeros(1, num_inputs+1) 1 inputs_flattened(i, :, :)];
    end

    [beta, sigma] = mvregress(X, real_cursor_velocities);
    
    Ab = reshape(beta, [], num_outputs)';
    b = Ab(:, 1);
    A = Ab(:, 2:end);

    % Plot l2 norms for each data point, and norm of the cursor velocities.
    % figure; histogram(vecnorm(real_cursor_velocities - (inputs_flattened * A' + b'), 2, 2));
    % figure; histogram(vecnorm(real_cursor_velocities, 2, 2));
end

