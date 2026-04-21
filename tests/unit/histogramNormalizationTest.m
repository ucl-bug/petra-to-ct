classdef histogramNormalizationTest < matlab.unittest.TestCase
    %HISTOGRAMNORMALIZATIONTEST Unit tests for petraToCT.histogramNormalization.
    %
    % DESCRIPTION:
    %     Verifies that the image is scaled by the highest-intensity peak
    %     found among the top-N tallest histogram peaks. This "max(locs)"
    %     contract is subtle: the function does not divide by the tallest
    %     peak, but by the peak with the largest bin centre among those
    %     retained by findpeaks, so that the soft-tissue peak (which sits
    %     at a higher intensity than the background/noise peak in PETRA
    %     images) is mapped to 1. Tests exercise both orderings, the
    %     HistogramNPeaks=1 case, and the input-invariant scaling property.

    methods (TestClassSetup)
        function addSourceToPath(tc)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(root);
            tc.addTeardown(@() rmpath(root));
        end
    end

    methods (Test)

        function normalisesByHighestIntensityPeakWhenTallerPeakIsLower(tc)
            % Taller peak at lower intensity (100), smaller peak at higher
            % intensity (500). max(locs) picks 500 regardless of height.
            data = makeBimodal(100, 500, 100, 20);

            out = petraToCT.histogramNormalization(data, HistogramPlot=false);

            tc.verifyEqual(out(1) / data(1), 1/500, 'AbsTol', 1e-10);
            tc.verifyEqual(max(out), max(data) / 500, 'AbsTol', 1e-10);
        end

        function normalisesByHighestIntensityPeakWhenTallerPeakIsHigher(tc)
            % Taller peak at higher intensity (500). Still divides by 500.
            data = makeBimodal(100, 500, 20, 100);

            out = petraToCT.histogramNormalization(data, HistogramPlot=false);

            tc.verifyEqual(out(1) / data(1), 1/500, 'AbsTol', 1e-10);
        end

        function nPeaksOneUsesTallestOnly(tc)
            % NPeaks = 1 drops the higher-intensity bone peak; divides by
            % the tallest peak's intensity (the soft-tissue peak at 100).
            data = makeBimodal(100, 500, 100, 20);

            out = petraToCT.histogramNormalization(data, ...
                HistogramPlot=false, ...
                HistogramNPeaks=1);

            tc.verifyEqual(out(1) / data(1), 1/100, 'AbsTol', 1e-10);
        end

        function scalingIsUniform(tc)
            % Every non-zero voxel should be scaled by the same factor.
            data = makeBimodal(100, 500, 50, 10);

            out = petraToCT.histogramNormalization(data, HistogramPlot=false);

            nonZero = data ~= 0;
            ratios = out(nonZero) ./ data(nonZero);
            tc.verifyEqual(max(ratios) - min(ratios), 0, 'AbsTol', 1e-12);
        end

        function preservesSizeAndClass(tc)
            data = single(makeBimodal(100, 500, 20, 5));

            out = petraToCT.histogramNormalization(data, HistogramPlot=false);

            tc.verifySize(out, size(data));
            tc.verifyClass(out, 'single');
        end

    end

end

function data = makeBimodal(centreA, centreB, heightA, heightB)
    % Generate a vector with two triangular histogram bumps at the given
    % centres. For each bump, bin count at centre is `height` and falls
    % off linearly to 1 at (centre ± height - 1). This places the peak
    % exactly on the centre bin, so findpeaks with
    % BinMethod='integers' returns the centre as the peak location.
    data = [triangularSamples(centreA, heightA); ...
            triangularSamples(centreB, heightB)];
end

function samples = triangularSamples(centre, height)
    offsets = (-(height - 1)):(height - 1);
    counts = height - abs(offsets);
    samples = repelem(centre + offsets(:), counts(:));
end

