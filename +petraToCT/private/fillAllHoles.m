function img = fillAllHoles(img, dilationSize, dims)
%FILLALLHOLES Fill all holes in a binary image.
%
% DESCRIPTION:
%     fillAllHoles fills all holes in a binary image using the following
%     approach:
%         1. Dilating the image by dilationSize
%         2. Filling holes by sweeping over 2D planes in the directions
%            specified by dims and calling imfill(plane, 'holes')
%         3. Eroding the filled image by dilationSize
% 
% USAGE:
%     img = fillAllHoles(img)
%     img = fillAllHoles(img, dilationSize)
%     img = fillAllHoles(img, dilationSize, dims)
%
% INPUTS:
%     img           - 2D or 3D logical matrix.
%
% OPTIONAL INPUTS:
%     dilationSize  - Dilation size in pixels. Default = 3.
%     dims          - Dimensions over which to sweep. Default = [1, 2, 3].
%
% ABOUT:
%     author        - Bradley E. Treeby
%     date          - 19 July 2022
%     last update   - 19 June 2023

% Copyright (C) 2023- University College London (Bradley Treeby).

arguments
    img logical;
    dilationSize {mustBeNumeric} = 3;
    dims {mustBeNumeric} = [1, 2, 3];
end

% dilate image
if ndims(img) == 3
    img = imdilate(img, strel('sphere', dilationSize));
else
    img = imdilate(img, strel('disk', dilationSize));
end

% sweep through 2D planes in the specified Cartesian direction filling the
% holes using imfill
for dim_ind = 1:length(dims)
    dim = dims(dim_ind);
    for layer_ind = 1:size(img, dim)
        switch dim
            case 1
                img(layer_ind, :, :) = imfill(squeeze(img(layer_ind, :, :)), 'holes');
            case 2
                img(:, layer_ind, :) = imfill(squeeze(img(:, layer_ind, :)), 'holes');
            case 3
                img(:, :, layer_ind) = imfill(squeeze(img(:, :, layer_ind)), 'holes');
        end
    end
end

% erode image
if ndims(img) == 3
    img = imerode(img, strel('sphere', dilationSize));
else
    img = imerode(img, strel('disk', dilationSize));
end
