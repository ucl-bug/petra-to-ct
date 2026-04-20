function measure = radius2measure(radius, dim)
%RADIUS2MEASURE Compute the measure from the radius.
%
% DESCRIPTION:
%     radius2measure computes the area or volume (collectively called the
%     measure) from the radius.
%
% USAGE:
%     measure = radius2measure(radius, dim)
%
% INPUTS:
%     radius        - Radius [m].
%     dim           - Dimension (2 or 3).
%
% OUTPUTS
%     measure       - Area (dim = 2) or Volume (dim = 3).
%
% ABOUT:
%     author        - Bradley E. Treeby
%     date          - 19 July 2022
%     last update   - 19 July 2022

arguments
    radius (1, 1) {isnumeric}
    dim (1, 1) {isnumeric, mustBeInRange(dim, 2, 3)}
end

switch dim
    case 2
        measure = pi * radius^2;
    case 3
        measure = 4/3 * pi * radius^3;
end
