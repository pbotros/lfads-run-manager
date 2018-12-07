function spike_data = tile_spikes(raw_spike_data, lags)
    num_time_steps = size(raw_spike_data, 1);
    num_time_steps_lagged = num_time_steps - lags + 1;
    num_channels = size(raw_spike_data, 2);

    spike_data = zeros(num_time_steps_lagged, lags * num_channels);
    for lag = 1:lags
       spike_data(1:num_time_steps_lagged, (1+num_channels*(lag - 1)):num_channels*lag) ...
           = raw_spike_data((lag):(lag + num_time_steps_lagged - 1), :);
    end
end