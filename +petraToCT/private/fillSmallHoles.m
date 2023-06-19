function img = fillSmallHoles(img, options)
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
%     img = fillSmallHoles(img, options)
%
% INPUTS:
%     img           - 2D or 3D logical matrix.
%
% OPTIONAL INPUTS:
%     Specify optional pairs of arguments as Name1=Value1, where |Name| is
%     the argument name and |Value| is the corresponding value. Name-value
%     arguments must appear after other arguments, but the order of the
%     pairs does not matter.
%
%     ImCloseSphereRadius   - Radius using for 'sphere' morphological
%                             structuring element used with imclose.
%                             Default = 1.
%     MaximumHoleRadius     - Maximum hole size used to set the number of
%                             pixels for bwareaopen, where P =
%                             ceil(radius2measure(radius)).
%
% ABOUT:
%     author        - Bradley E. Treeby
%     date          - 19 July 2022
%     last update   - 19 June 2023

% Copyright (C) 2023- University College London (Bradley Treeby).

arguments
    img logical;
    options.ImCloseSphereRadius = 1;
    options.MaximumHoleRadius {mustBeNumeric} = 3;
end

% morphologically close the image
img = imclose(img, strel('sphere', options.ImCloseSphereRadius));

% identify the hole pixels using logical operator
filled = imfill(img, 'holes');
holes = filled & ~img;

% use bwareaopen on the holes image to eliminate small holes
bigholes = bwareaopen(holes, ceil(radius2measure(options.MaximumHoleRadius, ndims(img))));

% use logical operators to identify small holes
smallholes = holes & ~bigholes;

% use a logical operator to fill in the small holes in the original image
img = img | smallholes;
