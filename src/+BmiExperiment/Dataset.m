classdef Dataset < LFADS.Dataset
    properties
        dayIndex = 0
    end
    methods
        function ds = Dataset(collection, relPath, dayIndex)
            ds = ds@LFADS.Dataset(collection, relPath);
            ds.dayIndex = dayIndex;
        end

        function data = loadData(ds)
            all_data = load(ds.path);
            unit_type = 'direct'; 
            raw_data_direct = all_data.PacoBMI.(ds.dayIndex).rearranged_neuraldata.direct;
            if strcmp(unit_type, 'all')==1
                raw_data_indirect_near = all_data.PacoBMI.(ds.dayIndex).rearranged_neuraldata.indirect_ipsi_near; 
                raw_data_indirect_far = all_data.PacoBMI.(ds.dayIndex).rearranged_neuraldata.indirect_ipsi_far; 
            
                indirect_near_mat = vertcat(raw_data_indirect_near {1:end});
                indirect_near_ind = find(~any(isnan(indirect_near_mat),1)); 
                indirect_far_mat = vertcat(raw_data_indirect_far {1:end});
                indirect_far_ind = find(~any(isnan(indirect_far_mat),1)); 
            
                raw_data = cell(size(raw_data_direct)); 
                for t = 1:size(raw_data,1); 
                    raw_data{t} = [raw_data_direct{t}, ...
                        raw_data_indirect_near{t}(:,indirect_near_ind), ...
                        raw_data_indirect_far{t}(:,indirect_far_ind)]; 
                end
            elseif strcmp(unit_type, 'direct')==1
                raw_data = raw_data_direct; 
            else 
                error('Unit type not recognized. Use "direct" or "all"')
            end

            trialIdxsToUse = [];
            for i = 1:size(raw_data , 1)
                timeBinCount = size(raw_data{i}, 1);
                if timeBinCount >= 10
                    trialIdxsToUse(size(trialIdxsToUse, 2) + 1) = i;
                end
            end
            nTrials = size(trialIdxsToUse, 2);
            nTime = 10;
            nChannels = size(raw_data{1}, 2);

            spikes = zeros(nTrials, nChannels, nTime, 1);
            targets = zeros(nTrials, 1);
            
            spike_trial_idx = 1;
            for trialIdx = trialIdxsToUse
                targets(spike_trial_idx) = all_data.PacoBMI.(ds.dayIndex).targets(trialIdx);
                for channelIdx = 1:nChannels
                    for timeIdx = 1:nTime
                        trial_data = raw_data{trialIdx};
                        spikes(spike_trial_idx, channelIdx, timeIdx) = trial_data(timeIdx, channelIdx);
                    end
                end
                spike_trial_idx = spike_trial_idx + 1;
            end
            
            data = struct;
            data.spikes = spikes;
            data.targets = targets;
            data.trialIdxs = trialIdxsToUse;
        end

        function loadInfo(ds, reload)
            % Load this Dataset's metadata if not already loaded

            if nargin < 2 
                reload = false;
            end
            if ds.infoLoaded && ~reload, return; end

            % modify this to extract the metadata loaded from the data file
            ds.infoLoaded = true;
        end

    end
end
