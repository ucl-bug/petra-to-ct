function [headMask, skullMask] = segmentationSPM12(inputFilename, options)

arguments
    inputFilename {mustBeFile}
    options.RunSegmentation (1,1) logical = true
    options.DeleteSegmentation (1,1) logical = true
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
skullMask = fillSmallHoles(skullMask, 50);

% Delete segmentation images.
if options.DeleteSegmentation
    for ind = 1:5
        delete(fullfile(pathname, ['c' num2str(ind) filename ext2 ext1]));
    end
    delete(fullfile(pathname, [filename '_seg8.mat']));
end
