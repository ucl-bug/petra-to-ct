function pctFilename = convert(inputFilename, options)
%CONVERT Convert PETRA image to pseudo-CT.
%
% DESCRIPTION:
%     convert converts a PETRA image to a pseudo-CT using the following
%     steps:
%
%         1. Debiasing the image using N4ITK MRI bias correction
%         2. Applying histogram normalisation to shift the soft-tissue peak
%            to 1.
%         3. Segmenting the skull and head in the image using SPM,
%            followed by morphological operations in MATLAB.
%         4. Applying a linear mapping to MR voxel values in the skull
%            bone, and using fixed values elsewhere in the head.
%
%     See https://github.com/ucl-bug/petra-to-ct for further details.
%
% USAGE:
%     pctFilename = petraToCT.convert(inputFilename)
%     petraToCT.convert(inputFilename, outputFilename, options)
%
% INPUTS:
%     inputFilename         - Pathname / filename for input nifti image.
%     outputFilename        - Pathname / filename for output nifti image
%                             (optional). If not defined, the output image
%                             is given the same name as the input, with
%                             '-pct' appended.
%
% OUTPUTS:
%     pctFilename           - Pathname / filename for output nifti image.
%
% OPTIONAL INPUTS:
%     Specify optional pairs of arguments as Name1=Value1, where |Name| is
%     the argument name and |Value| is the corresponding value. Name-value
%     arguments must appear after other arguments, but the order of the
%     pairs does not matter.
%
%     Debias                - Boolean controlling whether the image is
%                             debiased using N4ITK MRI bias correction.
%                             Default = true. Can be set to false to use a
%                             debiased image from a previous function call.
%     HeadThreshold         - Threshold for head mask. Default = 0.5.
%     HistogramMinPeakDistance
%                           - Minimum distance between histogram peaks.
%                             Default = 50.
%     HistogramNPeaks       - Number of histogram peaks to find. Default =
%                             2.
%     HistogramPlot         - Boolean to plot histogram. Default = true.
%     MaskPlot              - Boolean to plot masks. Default = false.
%     OutputDir             - Directory for saving output images. Defaults
%                             to '<inputFolder>/PetraToCT'.
%     RunSegmentation       - Boolean controlling whether the SPM
%                             segmentation is called. Default = true. Can
%                             be set to false to use the SPM masks from a
%                             previous function call.
%     SkullMaskMaximumHoleRadius
%                           - Maximum hole radius to fill. Default = 100.
%     SkullMaskSmoothing    - Skull smoothing factor used to set the radius
%                             using for the 'sphere' morphological
%                             structuring element used with imclose as part
%                             of fillSmallHoles. Default = 1.
%     SkullThreshold        - Threshold for skull mask. Default = 0.5.

arguments
    inputFilename {mustBeFile}
    options.Debias (1,1) logical = true
    options.HeadThreshold (1,1) {mustBeNumeric, mustBePositive} = 0.5;
    options.HistogramMinPeakDistance (1,1) {mustBeInteger, mustBePositive} = 50
    options.HistogramNPeaks (1,1) {mustBeInteger, mustBePositive} = 2
    options.HistogramPlot (1,1) logical = true
    options.MaskPlot (1,1) logical = false
    options.OutputDir {mustBeFolder}
    options.RunSegmentation (1,1) logical = true
    options.SegmentationMethod = 'SPM'
    options.SkullMaskMaximumHoleRadius (1,1) {mustBeNumeric, mustBePositive} = 50
    options.SkullMaskSmoothing (1,1) {mustBeNumeric, mustBePositive} = 1;
    options.SkullThreshold (1,1) {mustBeNumeric, mustBePositive} = 0.5;
end

import petraToCT.*

% Set output directory
if ~isfield(options, 'OutputDir')
    [pathname, ~, ~] = fileparts(inputFilename);
    options.OutputDir = [pathname filesep 'PetraToCT'];
end

% Create output directory if it doesn't exist.
if ~exist(options.OutputDir, 'dir')
    mkdir(options.OutputDir);
end

% Set output filenames.
pctFilename = fullfile(options.OutputDir, 'pct.nii.gz');
debiasedFilename = fullfile(options.OutputDir, 'debiased.nii.gz');

% Debias the image.
if options.Debias
    debias(inputFilename, debiasedFilename);
elseif ~exist(debiasedFilename, "file")
    error('Debiased image file not found. Run again with Debias=true.');
end


% Get segmentation.
switch options.SegmentationMethod
    case 'SPM'
        [headMask, skullMask] = segmentationSPM(debiasedFilename, ...
            HeadThreshold=options.HeadThreshold, ...    
            MaskPlot=options.MaskPlot, ...
            OutputDir=options.OutputDir, ...
            RunSegmentation=options.RunSegmentation, ...
            SkullMaskMaximumHoleRadius=options.SkullMaskMaximumHoleRadius, ...
            SkullMaskSmoothing=options.SkullMaskSmoothing, ...
            SkullThreshold=options.SkullThreshold ...
            );
    otherwise
        error('Unknown segmentation option.');
end

% Load image data.
imageDataNii = load_nii(debiasedFilename);

% Histogram normalisation.
imageData = histogramNormalization(single(imageDataNii.img), ...
    HistogramPlot=options.HistogramPlot, ...
    HistogramNPeaks=options.HistogramNPeaks, ...
    HistogramMinPeakDistance=options.HistogramMinPeakDistance);

% Convert image.
pCT = -1000 * ones(size(imageData));
pCT(headMask == 1) = 42;
pCT(skullMask == 1) = -2929.6 * imageData(skullMask == 1) + 3274.9;

% Save output re-using header of input file.
imageDataNii.img = int16(pCT);
imageDataNii.hdr.dime.bitpix = 16;
imageDataNii.hdr.dime.dataType = 4;
imageDataNii.hdr.dime.glmax = max(imageDataNii.img(:));
imageDataNii.hdr.dime.glmin = min(imageDataNii.img(:));
imageDataNii.hdr.dime.scl_slope = 1;
imageDataNii.hdr.dime.scl_inter = 0;
imageDataNii.hdr.hist.descrip = 'pseudoCT';

save_nii(imageDataNii, pctFilename);
