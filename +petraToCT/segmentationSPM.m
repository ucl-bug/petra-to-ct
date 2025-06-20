function [headMask, skullMask] = segmentationSPM(inputFilename, options)
%SEGMENTATIONSPM Segment nifti image using SPM.
%
% DESCRIPTION:
%     segmentationSPM segments a nifti image using SPM. The skull and
%     head masks returned by SPM are then processed using morphological
%     operations to remove holes.
%
% USAGE:
%     [headMask, skullMask] = petraToCT.segmentationSPM(inputFilename, options)
%
% INPUTS:
%     inputFilename         - Pathname / filename for input image in nifti
%                             format.
%
% OUTPUTS:
%     headMask              - Head segmentation.
%     skullMask             - Skull segmentation.
%
% OPTIONAL INPUTS:
%     Specify optional pairs of arguments as Name1=Value1, where |Name| is
%     the argument name and |Value| is the corresponding value. Name-value
%     arguments must appear after other arguments, but the order of the
%     pairs does not matter.
%
%     HeadThreshold         - Threshold for head mask. Default = 0.5.
%     MaskPlot              - Boolean controlling whether the masks are
%                             plotted using sliceViewer. Default = false.
%     OutputDir             - Directory for saving SPM images. Default is
%                             the same directory as the input image.
%     RunSegmentation       - Boolean controlling whether the SPM
%                             segmentation is called. Default = true. Can
%                             be set to false to re-use a previous
%                             segmentation.
%     SkullMaskMaximumHoleRadius
%                           - Maximum hole radius to fill. Default = 100.
%     SkullMaskSmoothing    - Skull smoothing factor used to set the radius
%                             using for the 'sphere' morphological
%                             structuring element used with imclose as part
%                             of fillSmallHoles. Default = 1.
%     SkullThreshold        - Threshold for skull mask. Default = 0.5.

% Copyright (C) 2023- University College London (Bradley Treeby).

arguments
    inputFilename {mustBeFile}
    options.HeadThreshold (1,1) {mustBeNumeric, mustBePositive} = 0.5;
    options.MaskPlot (1,1) logical = false
    options.OutputDir = []
    options.RunSegmentation (1,1) logical = true
    options.SkullMaskMaximumHoleRadius (1,1) {mustBeNumeric, mustBePositive} = 100
    options.SkullMaskSmoothing (1,1) {mustBeNumeric, mustBePositive} = 2;
    options.SkullThreshold (1,1) {mustBeNumeric, mustBePositive} = 0.5;
end

% Unzip if .nii.gz file.
[pathname, filenname, ext] = fileparts(inputFilename);
deleteUnzippedImage = false;
if strcmp(ext, '.gz')
    inputFilename = fullfile(pathname, filenname);
    if options.RunSegmentation
        gunzip([inputFilename '.gz']);
        deleteUnzippedImage = true;
    end
end

% Set output directory
if isempty(options.OutputDir)
    [pathname, ~, ~] = fileparts(inputFilename);
    options.OutputDir = pathname;
end

% Run segmentation.
if options.RunSegmentation
    runSPMSegmentation(inputFilename, options.OutputDir)
end

% Load masks.
headMaskFilename = fullfile(options.OutputDir, 'spm_soft_tissue_seg.nii');
skullMaskFilename = fullfile(options.OutputDir, 'spm_bone_seg.nii');

headMask = load_nii(headMaskFilename);
skullMask = load_nii(skullMaskFilename);

if options.MaskPlot
    plot_image = cat(1, headMask.img, skullMask.img);
end

headMask = (headMask.img > options.HeadThreshold);
skullMask = (skullMask.img > options.SkullThreshold);

% Get largest connected component.
headMask = getLargestCC(headMask);
skullMask = getLargestCC(skullMask);

if options.MaskPlot
    plot_image = cat(2, plot_image, cat(1, headMask, skullMask));
end

% Fill holes in the head mask.
headMask = fillAllHoles(headMask, 3, 3);

% Fill small holes in the skull mask.
skullMask = fillSmallHoles(skullMask, ...
    MaximumHoleRadius=options.SkullMaskMaximumHoleRadius, ...
    ImCloseSphereRadius=options.SkullMaskSmoothing);

if options.MaskPlot
    plot_image = cat(2, plot_image, cat(1, headMask, skullMask));
    figure;
    sliceViewer(plot_image)
    title('SPM Masks / Thresholded Masks / Filled Masks')
end

% Delete unzipped gz image.
if deleteUnzippedImage
    delete(inputFilename);
end
