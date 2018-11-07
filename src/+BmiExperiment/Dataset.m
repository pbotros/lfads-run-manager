classdef Dataset < LFADS.Dataset
    methods
        function ds = Dataset(collection, relPath, dayIndex)
            ds = ds@LFADS.Dataset(collection, relPath);
            ds.dayIndex = dayIndex;
        end

        function data = loadData(ds)
            all_data = load(ds.path);
            
            % read the data, ds.dayIndex
        end

        function loadInfo(ds, reload)
            % Load this Dataset's metadata if not already loaded

            if nargin < 2 
                reload = false;
            end
            if ds.infoLoaded && ~reload, return; end

            % modify this to extract the metadata loaded from the data file
            data = ds.loadData();
            ds.nTime = 1;
            ds.nChannels = size(data.spikes, 2);
            ds.nTrials = size(data.spikes, 1);

            ds.infoLoaded = true;
        end

    end
end
