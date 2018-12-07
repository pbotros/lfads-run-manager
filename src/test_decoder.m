function [cursor_params, joint_params] = test_decoder(day_idx, trial_idx)
    % UNUSED, OLD

   % For spikes data
   load('/Volumes/DATA_01/ELZ/VS265/PacoBMI_days.mat', 'PacoBMI');
   
   load('~/Development/lfads-run-manager/out/generated_kinematic_data.mat', 'kinematic_data');

    % spike data for the channels that we have predictions for
   day_str = sprintf('Day%02d', day_idx);
   raw_spike_data = PacoBMI.(day_str).rearranged_neuraldata.direct{trial_idx};
   
   % [ahat, mu, R2_fit, yhat_fit, Xused, var_ahat, t_ahat] = linmodel(Y,spike_times(:, s.channels_used),lags,[]);
   [R2_pred, yhat_pred] = linpred(...
       kinematic_data.(day_str).predicted_joint_params{trial_idx}',...
       raw_spike_data, ...
       kinematic_data.model.ahat, kinematic_data.model.mu);

   % Should be 1
   R2_pred
end