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
            data = all_data.PacoBMI.(ds.dayIndex).rearranged_neuraldata.direct;
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
