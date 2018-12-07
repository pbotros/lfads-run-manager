function kinematic_data = generate_kinematic_data()    
    % This file generates kinematic data based on the calibration data
    % found from original data (i.e. July 15th recordings of Paco, see
    % load_kg_data()), and then generates predicted joint angles and
    % velocities based on the spikes for each day found in PacoBMI.
    %
    % Note that this is not the source-of-truth kinematic data; we could
    % not find joint angles/velocities that were used that matched with the
    % given ahat matrix. The real process likely used a low-pass filter and
    % some transformations to display a cursor on the screen.
    % Use with caution.
    %
    % Returns kinematic_data, a struct with first-level properties of
    % Day01, Day02, etc.
    % Within those, are predicted_joint_params and predicted_cursor_params,
    % each <num_trialsx1> cells. The joint params are [elbow angular
    % position (rad), shoulder angular position (rad), elbow angular
    % velocity (rad/s), shoulder angular velocity (rad/s)].
    % The cursor params are generated from the joint params via a Jacobian,
    % see joint_to_cursor.

    s = load_kg_data();

    load('/Volumes/DATA_01/ELZ/VS265/PacoBMI_days.mat', 'PacoBMI');
    lags = 10;
    kinematic_data = struct;
    for day_idx = 1:18
        day_str = sprintf('Day%02d', day_idx);
        num_trials = size(PacoBMI.(day_str).neuraldata.direct, 1);
        kinematic_data.(day_str).predicted_joint_params = cell(num_trials, 1);
        kinematic_data.(day_str).predicted_cursor_params = cell(num_trials, 1);
        for trial_idx = 1:num_trials
            % TODO: use rearranged neural data?
            raw_spike_data = PacoBMI.(day_str).rearranged_neuraldata.direct{trial_idx};

            spike_times = tile_spikes(raw_spike_data, lags);
            mu_rep = repmat(s.mu, 1, size(spike_times, 1));

            predicted_joint_params = zeros(4, size(raw_spike_data, 1));
            predicted_joint_params(:, lags:end) = s.ahat * spike_times' + mu_rep;

            kinematic_data.(day_str).predicted_joint_params{trial_idx} = predicted_joint_params;
            
            predicted_cursor_params = zeros(4, size(raw_spike_data, 1));
            for t = 1:(size(raw_spike_data, 1) - lags)
                [px, py, vx, vy] = joint_to_cursor(...
                    predicted_joint_params(1, t), ...
                    predicted_joint_params(2, t), ...
                    predicted_joint_params(3, t), ...
                    predicted_joint_params(4, t));
                predicted_cursor_params(:, lags + (t-1)) = [ ...
                    px, ...
                    py, ...
                    vx, ...
                    vy];
            end
            kinematic_data.(day_str).predicted_cursor_params{trial_idx} = predicted_cursor_params;
        end
    end
end