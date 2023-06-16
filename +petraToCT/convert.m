function outputFilename = convert(inputFilename, outputFilename, options)
%     1. Debias
%     2. Get masks
%     3. Histogram normalization
%     4. Generate pCT

arguments
    inputFilename {mustBeFile}
    outputFilename = []
    options.SegmentationMethod = 'SPM12'
    options.RunSegmentation (1,1) logical = true
    options.DeleteSegmentation (1,1) logical = true    
end

import petraToCT.*

% Set output filename.
if isempty(outputFilename)
    [pathname, filename, ext1] = fileparts(inputFilename);
    [~, filename, ext2] = fileparts(filename);
    outputFilename = fullfile(pathname, [filename '-pct' ext2 ext1]);
end

% Debias the image.
debiasedFilename = debias(inputFilename);

% Get segmentation.
switch options.SegmentationMethod
    case 'SPM12'
        [headMask, skullMask] = segmentationSPM12(debiasedFilename, ...
            RunSegmentation=options.RunSegmentation, ...
            DeleteSegmentation=options.DeleteSegmentation);
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
