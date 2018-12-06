function predicted_cursors = test_decoder(day_idx, trial_idx)
   s = load_kg_data();
   load('/Volumes/DATA_01/ELZ/VS265/PacoBMI_days.mat', 'PacoBMI');
   
   % Day05
   load('~/Desktop/KG_MAT/BMI_model_data/Paco_prediction_19-Jul-2008_1.mat', 'N');

   [~, ia, ib] = intersect(s.channels_used, N);

   lags = s.lags;
    % spike data for the channels that were have predictions for
   day_str = sprintf('Day%02d', day_idx);
   raw_spike_data = PacoBMI.(day_str).neuraldata.direct{trial_idx}(:, ib);
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
%    [b,a]=butter(filt_order,fnorm,'low');
%    filtered_predicted_cursors_x = filter(b, a, predicted_cursors(1, :));
%    filtered_predicted_cursors_y = filter(b, a, predicted_cursors(2, :));
   
   filtered_predicted_cursors_x = predicted_cursors(1, :);
   filtered_predicted_cursors_y = predicted_cursors(2, :);
   
   GAIN_X=1.2;
   GAIN_Y=1.2;
   center_x_pos=(2*0.01+ 0.0089);
   center_y_pos=(2.5*0.01+0.1335);

   final_x = center_x_pos + ...
       (filtered_predicted_cursors_x - center_x_pos)*GAIN_X - 0.01;
   final_y = center_y_pos + ...
       (filtered_predicted_cursors_y - center_y_pos)*GAIN_Y + 0.02;
   final_x(final_x > 0.1) = 0.1;
   final_x(final_x < -0.04) = -0.04;
   final_y(final_y < 0.08) = 0.08;
   final_y(final_y > 0.25) = 0.25;
     
   final_x
   final_y
end