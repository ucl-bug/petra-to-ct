function [headMask, skullMask] = segmentationSPM12(inputFilename, options)
%SEGMENTATIONSPM12 Segment nifti image using SPM12.
%
% DESCRIPTION:
%     segmentationSPM12 segments a nifti image using SPM12. The skull and
%     head masks returned by SPM are then processed using morphological
%     operations to remove holes.
%
% USAGE:
%     [headMask, skullMask] = segmentationSPM12(inputFilename, options)
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
%     DeleteSegmentation    - Boolean controlling whether the raw SPM12
%                             segmentation files are deleted. Default =
%                             true.
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

% Copyright (C) 2023- University College London (Bradley Treeby).

arguments
    inputFilename {mustBeFile}
    options.DeleteSegmentation (1,1) logical = true
    options.RunSegmentation (1,1) logical = true
    options.SkullMaskMaximumHoleRadius (1,1) {mustBeNumeric, mustBePositive} = 5
    options.SkullMaskSmoothing (1,1) {mustBeNumeric, mustBePositive} = 1;
end

% Run segmentation.
if options.RunSegmentation
    runSPMSegmentation(inputFilename)
end

% Load masks.
[pathname, filename, ext1] = fileparts(inputFilename);
[~, filename, ext2] = fileparts(filename);

headMaskFilename = fullfile(pathname, ['c5' filename ext2 ext1]);
skullMaskFilename = fullfile(pathname, ['c4' filename ext2 ext1]);

headMask = load_nii(headMaskFilename);
skullMask = load_nii(skullMaskFilename);

headMask = (headMask.img > 0.75);
skullMask = (skullMask.img > 0.75);

% Get largest connected component.
headMask = getLargestCC(headMask);
skullMask = getLargestCC(skullMask);

% Fill holes in the head mask.
headMask = fillAllHoles(headMask, 3, 3);

% Fill small holes in the skull mask.
skullMask = fillSmallHoles(skullMask, ...
    MaximumHoleRadius=options.SkullMaskMaximumHoleRadius, ...
    ImCloseSphereRadius=options.SkullMaskSmoothing);

% Delete segmentation images.
if options.DeleteSegmentation
    for ind = 1:5
        delete(fullfile(pathname, ['c' num2str(ind) filename ext2 ext1]));
    end
    delete(fullfile(pathname, [filename '_seg8.mat']));
end
