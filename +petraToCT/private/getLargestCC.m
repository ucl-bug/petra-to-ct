function bw_img = getLargestCC(bw_img, number_cc)
%GETLARGESTCC Select largest connected components in a binary image.
%
% DESCRIPTION:
%     getLargestCC selects the largest connected components in a binary
%     image. The number of connected to components can be specified using
%     number_cc.
%
% USAGE:
%     bw_img = getLargestCC(bw_img)
%     bw_img = getLargestCC(bw_img, number_cc)
%
% INPUTS:
%     bw_img        - 2D or 3D logical matrix.
%
% OPTIONAL INPUTS:
%     number_cc     - Number of connected components to retain. Default =
%                     1.
%
% ABOUT:
%     author        - Bradley E. Treeby
%     date          - 19 July 2022
%     last update   - 20 July 2022

arguments
    bw_img logical;
    number_cc {mustBeNumeric} = 1;
end

% find connected components
cc = bwconncomp(bw_img);
numPixels = cellfun(@numel, cc.PixelIdxList);
[~, idx] = sort(numPixels, 'descend');

% keep largest components
bw_img = false(size(bw_img));
for cc_ind = 1:min(length(idx), number_cc)
    bw_img(cc.PixelIdxList{idx(cc_ind)}) = true;
end
