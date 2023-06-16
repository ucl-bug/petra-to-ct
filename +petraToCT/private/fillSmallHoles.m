function bw_img = fillSmallHoles(bw_img, radius)
%FILLSMALLHOLES Fill small holes in a binary image.
%
% DESCRIPTION:
%     fillSmallHoles fills small holes in a binary image by using
%     bwareaopen on the negative of the image, and then adding the filled
%     components to the binary image.
% 
%     See also:
%     https://blogs.mathworks.com/steve/2008/08/05/filling-small-holes/ 
%
% USAGE:
%     bw_img = fillSmallHoles(bw_img, max_hole_size)
%
% INPUTS:
%     bw_img        - 2D or 3D logical matrix.
%
% OPTIONAL INPUTS:
%     radius        - Hole size used to set the number of pixels for
%                     bwareaopen, where P = ceil(radius2measure(radius)).
%
% ABOUT:
%     author        - Bradley E. Treeby
%     date          - 19 July 2022
%     last update   - 16 June 2023

arguments
    bw_img logical;
    radius {mustBeNumeric} = 3;
end

% morphologically close the image
bw_img = imclose(bw_img, strel('sphere', 1));

% identify the hole pixels using logical operator
filled = imfill(bw_img, 'holes');
holes = filled & ~bw_img;

% use bwareaopen on the holes image to eliminate small holes
bigholes = bwareaopen(holes, ceil(radius2measure(radius, ndims(bw_img))));

% use logical operators to identify small holes
smallholes = holes & ~bigholes;

% use a logical operator to fill in the small holes in the original image
bw_img = bw_img | smallholes;
