function [headMask, skullMask] = segmentationSPM(inputFilename, options)
%SEGMENTATIONSPM Segment nifti image using SPM.
%
% DESCRIPTION:
%     segmentationSPM segments a nifti image using SPM. The skull and
%     head masks returned by SPM are then processed using morphological
%     operations to remove holes.
%
% USAGE:
%     [headMask, skullMask] = segmentationSPM(inputFilename, options)
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
%     DeleteSegmentation    - Boolean controlling whether the raw SPM
%                             segmentation files are deleted. Default =
%                             true.
%     RunSegmentation       - Boolean controlling whether the SPM
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

% Run segmentation.
if options.RunSegmentation
    runSPMSegmentation(inputFilename)
end

% Load masks.
[pathname, filename, ~] = fileparts(inputFilename);

headMaskFilename = fullfile(pathname, ['c5' filename '.nii']);
skullMaskFilename = fullfile(pathname, ['c4' filename '.nii']);

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
        delete(fullfile(pathname, ['c' num2str(ind) filename '.nii']));
    end
    delete(fullfile(pathname, [filename '_seg8.mat']));
end

% Delete unzipped gz image.
if deleteUnzippedImage
    delete(inputFilename);
end
