function imageData = histogramNormalization(imageData, options)
%HISTOGRAMNORMALIZATION Normalize PETRA or ZTE image.
%
% DESCRIPTION:
%     histogramNormalization normalises a PETRA or ZTE image following [1].
%     The image histogram is first computed, and the soft-tissue peak is
%     normalized to 1. The histogram normalization should be applied to
%     bias-corrected image (see debias). 
%
%     By default, a plot of the histogram is produced. This should contain
%     two clear peaks, which are labelled with vertical lines. If this
%     fails for some reason, try increasing the values for NPeaks and
%     MinPeakDistance until the last vertical line intersects the highest
%     peak in the histogram.
%
%     [1] Wiesinger, F., Sacolick, L.I., Menini, A., Kaushik, S.S., Ahn,
%     S., Veit‐Haibach, P., Delso, G. and Shanbhag, D.D., 2016. Zero TE MR
%     bone imaging in the head. Magnetic resonance in medicine, 75(1),
%     pp.107-114.
%
% USAGE:
%     imageData = petraToCT.histogramNormalization(imageData, options)
%
% INPUTS / OUTPUTS:
%     imageData - Image data to normalise.
%
% OPTIONAL INPUTS:
% Specify optional pairs of arguments as |Name1=Value1,...,NameN=ValueN|,
% where |Name| is the argument name and |Value| is the corresponding value.
% Name-value arguments must appear after other arguments, but the order of
% the pairs does not matter.
%       
%     Plot              - Boolean to plot histogram. Default = true.
%     NPeaks            - Number of histogram peaks to find. Default = 2.
%     MinPeakDistance   - Minimum distance between histogram peaks. Default
%                         = 50.

% Copyright (C) 2023- University College London (Bradley Treeby).

arguments
    imageData {mustBeNumeric, mustBeFinite}
    options.Plot (1,1) logical = true
    options.NPeaks (1,1) {mustBeInteger, mustBePositive} = 2
    options.MinPeakDistance (1,1) {mustBeInteger, mustBePositive} = 50
end

% Take histogram.
[hist_vals, edges] = histcounts(imageData(:), 'BinMethod', 'integers');
bins = (edges(2:end) + edges(1:end-1))/2;
bins(1) = [];
hist_vals(1) = [];

% Find peak corresponding to soft tissue.
[pks, locs] = findpeaks(hist_vals, bins, ...
    'SortStr', 'descend', ...
    'NPeaks', 2, ...
    'MinPeakDistance', options.MinPeakDistance);

% Plot histogram.
if options.Plot
    figure;
    plot(bins, hist_vals);
    hold on;
    for ind2 = 1:length(pks)
        xline(locs(ind2));
    end
    xlabel('ZTE Value');
    ylabel('Count');
    title('Image Histogram');
end

% Normalise data.
imageData = imageData ./ max(locs);
