function outputFilename = convert(inputFilename, outputFilename, options)
%CONVERT Convert PETRA image to pseudo-CT.
%
% DESCRIPTION:
%     convert converts a PETRA image to a pseudo-CT using the following
%     steps:
%
%         1. Debiasing the image using N4ITK MRI bias correction
%         2. Applying histogram normalisation to shift the soft-tissue peak
%            to 1. 
%         3. Segmenting the skull and head in the image using SPM12,
%            followed by morphological operations in MATLAB. 
%         4. Applying a linear mapping to MR voxel values in the skull
%            bone, and using fixed values elsewhere in the head.
%
%     See https://github.com/ucl-bug/petra-to-ct for further details.
%
% USAGE:
%     outputFilename = convert(inputFilename)
%     convert(inputFilename, outputFilename, options)
%
% INPUTS:
%     inputFilename         - Pathname / filename for input nifti image.
%     outputFilename        - Pathname / filename for output nifti image
%                             (optional). If not defined, the output image
%                             is given the same name as the input, with
%                             '-pct' appended.
%
% OUTPUTS:
%     outputFilename        - Pathname / filename for output nifti image.
%
% OPTIONAL INPUTS:
%     Specify optional pairs of arguments as Name1=Value1, where |Name| is
%     the argument name and |Value| is the corresponding value. Name-value
%     arguments must appear after other arguments, but the order of the
%     pairs does not matter.
%
%     DeleteSegmentation    - Boolean controlling whether the raw SPM12
%                             segmentation files are deleted. Default =
%                             true.
%     HistogramMinPeakDistance   
%                           - Minimum distance between histogram peaks.
%                             Default = 50.
%     HistogramNPeaks       - Number of histogram peaks to find. Default =
%                             2. 
%     HistogramPlot         - Boolean to plot histogram. Default = true.
%     RunSegmentation       - Boolean controlling whether the SPM12
%                             segmentation is called. Default = true. Can
%                             be set to false to re-use a previous
%                             segmentation called using DeleteSegmentation
%                             = false.
%     SkullMaskMaximumHoleRadius
%                           - Maximum hole radius to fill. Default = 5.
%     SkullMaskSmoothing    - Skull smoothing factor used to set the radius
%                             using for the 'sphere' morphological
%                             structuring element used with imclose as part
%                             of fillSmallHoles. Default = 1.

arguments
    inputFilename {mustBeFile}
    outputFilename = []
    options.Debias (1,1) logical = true
    options.DeleteSegmentation (1,1) logical = true
    options.HistogramMinPeakDistance (1,1) {mustBeInteger, mustBePositive} = 50
    options.HistogramNPeaks (1,1) {mustBeInteger, mustBePositive} = 2
    options.HistogramPlot (1,1) logical = true
    options.RunSegmentation (1,1) logical = true    
    options.SegmentationMethod = 'SPM12'
    options.SkullMaskMaximumHoleRadius (1,1) {mustBeNumeric, mustBePositive} = 5
    options.SkullMaskSmoothing (1,1) {mustBeNumeric, mustBePositive} = 1;
end

import petraToCT.*

% Set output filename.
if isempty(outputFilename)
    [pathname, filename, ~] = fileparts(inputFilename);
    [~, filename, ~] = fileparts(filename);
    outputFilename = fullfile(pathname, [filename '-pct.nii.gz']);
end

% Debias the image.
if options.Debias
    debiasedFilename = debias(inputFilename);
else
    debiasedFilename = inputFilename;
end

% Get segmentation.
switch options.SegmentationMethod
    case 'SPM12'
        [headMask, skullMask] = segmentationSPM12(debiasedFilename, ...
            RunSegmentation=options.RunSegmentation, ...
            DeleteSegmentation=options.DeleteSegmentation, ...
            SkullMaskMaximumHoleRadius=options.SkullMaskMaximumHoleRadius, ...
            SkullMaskSmoothing=options.SkullMaskSmoothing);
    otherwise
        error('Unknown segmentation option.');
end

% Load image data.
imageDataNii = load_nii(debiasedFilename);

% Histogram normalisation.
imageData = histogramNormalization(single(imageDataNii.img));

% Convert image.
pCT = -1000 * ones(size(imageData));
pCT(headMask == 1) = 42;
pCT(skullMask == 1) = -2928.8 * imageData(skullMask == 1) + 3274.6;

% Save output.
imageDataNii.img = int16(pCT);
imageDataNii.hdr.dime.bitpix = 16;
imageDataNii.hdr.dime.dataType = 4;
imageDataNii.hdr.dime.glmax = max(imageDataNii.img(:));
imageDataNii.hdr.dime.glmin = min(imageDataNii.img(:));
imageDataNii.hdr.dime.scl_slope = 1;
imageDataNii.hdr.dime.scl_inter = 0;
imageDataNii.hdr.hist.descrip = 'pseudoCT';

save_nii(imageDataNii, outputFilename);
