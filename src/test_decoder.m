function [cursor_params, joint_params] = test_decoder(day_idx, trial_idx)
    % UNUSED, OLD

   % For spikes data
   load('/Volumes/DATA_01/ELZ/VS265/PacoBMI_days.mat', 'PacoBMI');
   
   % Load AD33, AD34 data for angular position of shoulder elbow
   load('~/Desktop/paco_mat/paco080108/paco080108b_mat.mat');
   addpath('~/Desktop/KG_MAT');
   % There's two bin_all_data's that are different; run this one
   run('~/Desktop/KG_MAT/bin_all_data.m');
   
   % spike_times in workspace has <num time steps> x <all channels>
   s = load_kg_data();

   % Day18
   % load('~/Desktop/KG_MAT/BMI_model_data/Paco_prediction_19-Jul-2008_1.mat', 'N');
   % [~, ia, ib] = intersect(s.channels_used, N);
    
   load('~/Desktop/KG_MAT/BMI_model_data/Paco_prediction_15-Jul-2008_1.mat', 'ahat', 'mu');

   lags = s.lags;
    % spike data for the channels that we have predictions for
   % day_str = sprintf('Day%02d', day_idx);
   % raw_spike_data = PacoBMI.(day_str).neuraldata.direct{trial_idx}(:, ib);
   raw_spike_data = spike_times(:, s.channels_used);
   
   % [ahat, mu, R2_fit, yhat_fit, Xused, var_ahat, t_ahat] = linmodel(Y,spike_times(:, s.channels_used),lags,[]);
   [R2_pred, yhat_pred] = linpred(Y,spike_times(:, s.channels_used),ahat,mu);
   
   num_time_steps = size(raw_spike_data, 1);
   num_time_steps_lagged = num_time_steps - lags + 1;
   num_channels = size(raw_spike_data, 2);

   spike_data = zeros(num_time_steps_lagged, lags * num_channels);
   for lag = 1:lags
       spike_data(1:num_time_steps_lagged, (1+num_channels*(lag - 1)):num_channels*lag) ...
           = raw_spike_data((lag):(lag + num_time_steps_lagged - 1), :);
   end
   
   model_num_channels = size(s.ahat, 2)/lags;
   ahat = s.ahat;
%    ahat = zeros(size(s.ahat, 1), lags * num_channels);
%    for lag = 1:lags
%        offset = (lag - 1) * model_num_channels;
%        ahat(:, (1+num_channels*(lag - 1)):num_channels*lag) = ...
%            s.ahat(:, ia + offset);
%    end
   
   mu_rep = repmat(s.mu, 1, num_time_steps_lagged);
   
   predicted_joint_params = ahat * spike_data' + mu_rep;
   
   % same as linpred
   %[~, to_compare] = linpred(zeros(size(raw_spike_data, 1), 4), raw_spike_data, ahat, s.mu);

   predicted_cursors = zeros(4, num_time_steps_lagged);
   for time_idx = 1:num_time_steps_lagged
       [cx, cy, vx, vy] = joint_to_cursor(...
           predicted_joint_params(1, time_idx), ...
           predicted_joint_params(2, time_idx), ...
           predicted_joint_params(3, time_idx), ...
           predicted_joint_params(4, time_idx));
       predicted_cursors(:, time_idx) = [cx, cy, vx, vy];
   end

   % low-pass filter the predicted cursors in time
%    fnorm = (0.99999/(10/2));
%    filt_order=2;
%    n
%    filtered_predicted_cursors_x = filter(b, a, predicted_cursors(1, :));
%    filtered_predicted_cursors_y = filter(b, a, predicted_cursors(2, :));
   
   filtered_predicted_cursors_x = predicted_cursors(1, :);
   filtered_predicted_cursors_y = predicted_cursors(2, :);

   GAIN_X=1.2;
   GAIN_Y=1.2;
   center_x_pos=(2*0.01+ 0.0089);
   center_y_pos=(2.5*0.01+0.1335);

   % TODO: smooth with lowpass?
   % final_x = center_x_pos + ...
   %     (filtered_predicted_cursors_x - center_x_pos)*GAIN_X - 0.01;
   % final_y = center_y_pos + ...
   %     (filtered_predicted_cursors_y - center_y_pos)*GAIN_Y + 0.02;
   % final_x(final_x > 0.1) = 0.1;
   % final_x(final_x < -0.04) = -0.04;
   % final_y(final_y < 0.08) = 0.08;
   % final_y(final_y > 0.25) = 0.25;
   % cursor_params.px = final_x;
   % cursor_params.py = final_y;
   
   cursor_params = struct;
   
   cursor_params.px = predicted_cursors(1, :);
   cursor_params.py = predicted_cursors(2, :);
   cursor_params.vx = predicted_cursors(3, :);
   cursor_params.vy = predicted_cursors(4, :);
   
   joint_params.theta_s = predicted_joint_params(1, :);
   joint_params.theta_e = predicted_joint_params(2, :);
   joint_params.omega_s = predicted_joint_params(3, :);
   joint_params.omega_e = predicted_joint_params(4, :);
end