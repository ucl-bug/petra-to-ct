function bw_img = fillAllHoles(bw_img, dilat_sz, dims)
%FILLALLHOLES Fill all holes in a binary image.
%
% DESCRIPTION:
%     fillAllHoles fills all holes in a binary image using the following
%     approach:
%         1. Dilating the image by dilat_sz
%         2. Filling holes by sweeping over 2D planes in the directions
%            specified by dims and calling imfill(plane, 'holes')
%         3. Eroding the filled image by dilat_sz
% 
% USAGE:
%     bw_img = fillAllHoles(bw_img)
%     bw_img = fillAllHoles(bw_img, dilat_sz)
%     bw_img = fillAllHoles(bw_img, dilat_sz, dims)
%
% INPUTS:
%     bw_img        - 2D or 3D logical matrix.
%
% OPTIONAL INPUTS:
%     dilat_sz      - Dilation size in pixels. Default = 3.
%     dims          - Dimensions over which to sweep. Default = [1, 2, 3].
%
% ABOUT:
%     author        - Bradley E. Treeby
%     date          - 19 July 2022
%     last update   - 19 July 2022

arguments
    bw_img logical;
    dilat_sz {mustBeNumeric} = 3;
    dims {mustBeNumeric} = [1, 2, 3];
end

% dilate image
if numDim(bw_img) == 3
    bw_img = imdilate(bw_img, strel('sphere', dilat_sz));
else
    bw_img = imdilate(bw_img, strel('disk', dilat_sz));
end

% sweep through 2D planes in the specified Cartesian direction filling the
% holes using imfill
for dim_ind = 1:length(dims)
    dim = dims(dim_ind);
    for layer_ind = 1:size(bw_img, dim)
        switch dim
            case 1
                bw_img(layer_ind, :, :) = imfill(squeeze(bw_img(layer_ind, :, :)), 'holes');
            case 2
                bw_img(:, layer_ind, :) = imfill(squeeze(bw_img(:, layer_ind, :)), 'holes');
            case 3
                bw_img(:, :, layer_ind) = imfill(squeeze(bw_img(:, :, layer_ind)), 'holes');
        end
    end
end

% erode image
if numDim(bw_img) == 3
    bw_img = imerode(bw_img, strel('sphere', dilat_sz));
else
    bw_img = imerode(bw_img, strel('disk', dilat_sz));
end
