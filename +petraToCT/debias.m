function outputFilename = debias(inputFilename, outputFilename)
%DEBIAS Debias nifti image using N4ITK.
%
% DESCRIPTION:
%     debias debiases a nifti image using the N4ITKBiasFieldCorrection
%     module that is packaged with 3D Slicer. The number of iterations is
%     set to 50,40,30,20,10 to give an output image with a very uniform
%     image intensity.
%
%     For linux and windows, Slicer must already be installed and added to
%     system path. For example, in linux using:
%
%         export PATH="/path/to/Slicer-5.0.2-linux-amd64:$PATH"
%
%     Or in windows, typing "Environment Variables" into the search path,
%     and under System variables, Path, adding the root folder and bin
%     directory of Slicer to the path, e.g.,
%
%         C:\Users\username\AppData\Local\NA-MIC\Slicer 4.11.20210226
%         C:\Users\username\AppData\Local\NA-MIC\Slicer 4.11.20210226\bin
%
% USAGE:
%     outputFilename = petraToCT.debias(inputFilename)
%     petraToCT.debias(inputFilename, outputFilename)
%
% INPUTS / OUTPUTS:
%     inputFilename     - Pathname / filename for input nifti image.
%     outputFilename    - Pathname / filename for output nifti image. Can
%                         be left empty to auto-generate output file name.

% Copyright (C) 2023- University College London (Bradley Treeby).

arguments
    inputFilename char {mustBeFile}
    outputFilename = []
end

% Set output filename.
if isempty(outputFilename)
    [pathname, filename, ext1] = fileparts(inputFilename);
    [~, filename, ext2] = fileparts(filename);
    outputFilename = fullfile(pathname, [filename '-debiased' ext2 ext1]);
else
    validateattributes(outputFilename, {'char'}, {'nonempty', 'scalartext'});
end

% Debias.
if ismac

    % Find the N4ITKBiasFieldCorrection executable.
    [status, n4path] = system('find /Applications/Slicer.app -name "N4ITKBiasFieldCorrection" -type f 2>/dev/null | grep -E "cli-modules/N4ITKBiasFieldCorrection$" | head -1');
    n4path = strtrim(n4path);

    if isempty(n4path) || status ~= 0
        error('Could not find N4ITKBiasFieldCorrection executable. Make sure Slicer is installed in /Applications/.');
    end

    % Run the command directly.
    cmd = sprintf('"%s" "%s" "%s" --iterations 50,40,30,20,10', n4path, inputFilename, outputFilename);
    system(cmd);

elseif isunix
    system(['Slicer --launch N4ITKBiasFieldCorrection ' inputFilename ' ' outputFilename ' --iterations 50,40,30,20,10']);
else
    system(['START /W Slicer.exe --launch N4ITKBiasFieldCorrection.exe ' inputFilename ' ' outputFilename ' --iterations 50,40,30,20,10']);
end
