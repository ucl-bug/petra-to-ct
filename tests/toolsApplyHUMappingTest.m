classdef toolsApplyHUMappingTest < matlab.unittest.TestCase
    %TOOLSAPPLYHUMAPPINGTEST Unit tests for petraToCT.tools.applyHUMapping.
    %
    % DESCRIPTION:
    %     Pins the pseudo-CT Hounsfield unit mapping against accidental
    %     changes. The background, head (soft tissue), and skull (bone)
    %     values are hardcoded calibration derived from paired PETRA/CT
    %     data and must not drift silently. Values asserted here match
    %     the README and the values previously embedded in convert.m.

    methods (TestClassSetup)
        function addSourceToPath(tc)
            addpath(getSourceRoot());
            tc.addTeardown(@() rmpath(getSourceRoot()));
        end
    end

    methods (Test)

        function backgroundIsMinusOneThousand(tc)
            imageData = zeros(4, 4, 4, 'single');
            headMask  = false(4, 4, 4);
            skullMask = false(4, 4, 4);

            pCT = petraToCT.tools.applyHUMapping(imageData, headMask, skullMask);

            tc.verifyEqual(unique(pCT(:)), single(-1000));
        end

        function headIsFortyTwo(tc)
            imageData = zeros(4, 4, 4, 'single');
            headMask  = true(4, 4, 4);
            skullMask = false(4, 4, 4);

            pCT = petraToCT.tools.applyHUMapping(imageData, headMask, skullMask);

            tc.verifyEqual(unique(pCT(:)), single(42));
        end

        function skullUsesLinearCalibration(tc)
            % pCT = -2929.6 * imageData + 3274.9
            imageData = single([0, 1, 0.5, 1.5]);
            headMask  = true(size(imageData));
            skullMask = true(size(imageData));

            pCT = petraToCT.tools.applyHUMapping(imageData, headMask, skullMask);

            expected = single(-2929.6 * [0, 1, 0.5, 1.5] + 3274.9);
            tc.verifyEqual(pCT, expected, 'AbsTol', single(1e-3));
        end

        function skullOverridesHead(tc)
            % Skull voxels get the linear calibration even when they are
            % also marked as head (masks overlap in real use).
            imageData = single(ones(3, 3, 3));
            headMask  = true(3, 3, 3);
            skullMask = false(3, 3, 3);
            skullMask(2, 2, 2) = true;

            pCT = petraToCT.tools.applyHUMapping(imageData, headMask, skullMask);

            tc.verifyEqual(pCT(2, 2, 2), single(-2929.6 + 3274.9), ...
                'AbsTol', single(1e-3));
            % Surrounding head voxels untouched by skull mapping.
            other = pCT;
            other(2, 2, 2) = 42;
            tc.verifyEqual(unique(other(:)), single(42));
        end

        function compositeRegionValues(tc)
            % End-to-end check with all three regions present.
            imageData = single([0.2, 0.5, 1.0, 1.2]);
            headMask  = [false, true,  true,  true];
            skullMask = [false, false, true,  false];

            pCT = petraToCT.tools.applyHUMapping(imageData, headMask, skullMask);

            tc.verifyEqual(pCT(1), single(-1000));
            tc.verifyEqual(pCT(2), single(42));
            tc.verifyEqual(pCT(3), single(-2929.6 * 1.0 + 3274.9), ...
                'AbsTol', single(1e-3));
            tc.verifyEqual(pCT(4), single(42));
        end

        function preservesSizeAndClass(tc)
            imageData = single(rand(5, 6, 7));
            headMask  = true(5, 6, 7);
            skullMask = false(5, 6, 7);

            pCT = petraToCT.tools.applyHUMapping(imageData, headMask, skullMask);

            tc.verifySize(pCT, size(imageData));
            tc.verifyClass(pCT, 'single');
        end

    end

end
