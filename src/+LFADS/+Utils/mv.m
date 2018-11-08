function success = mv(src, dest)        
    LFADS.Utils.mkdirRecursive(fileparts(dest));

    cmd = sprintf('mv -f "%s" "%s"', src, dest);
    [status, output] = unix(cmd);
    
    if status
        fprintf('Error moving files: \n');
        fprintf('%s\n', output);
    end

    success = ~status;
end
