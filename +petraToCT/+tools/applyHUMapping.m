function pCT = applyHUMapping(imageData, headMask, skullMask)
%APPLYHUMAPPING Convert normalised PETRA to pseudo-CT Hounsfield units.
%
% DESCRIPTION:
%     applyHUMapping assigns Hounsfield unit values to a pseudo-CT:
%         - background (outside head) = -1000
%         - head (soft tissue)        =    42
%         - skull (bone)              = -2929.6 * imageData + 3274.9
%
%     The linear mapping for the skull is derived from paired PETRA and
%     low-dose CT images; see README.md for details.
%
% USAGE:
%     pCT = applyHUMapping(imageData, headMask, skullMask)
%
% INPUTS:
%     imageData     - Histogram-normalised PETRA image (numeric array).
%     headMask      - Logical mask of the head region, same size as
%                     imageData.
%     skullMask     - Logical mask of the skull region, same size as
%                     imageData. Assumed to be a subset of headMask.
%
% OUTPUTS:
%     pCT           - Pseudo-CT image in Hounsfield units, same size as
%                     imageData.

arguments
    imageData {mustBeNumeric}
    headMask  logical
    skullMask logical
end

pCT = -1000 * ones(size(imageData), 'like', imageData);
pCT(headMask)  = 42;
pCT(skullMask) = -2929.6 * imageData(skullMask) + 3274.9;
