function root = getSourceRoot()
    root = fileparts(fileparts(mfilename('fullpath')));
end
