classdef toolsGetLargestCCTest < matlab.unittest.TestCase
    %TOOLSGETLARGESTCCTEST Unit tests for petraToCT.tools.getLargestCC.
    %
    % DESCRIPTION:
    %     Verifies that getLargestCC retains the requested number of
    %     largest connected components in 2D and 3D binary images, and
    %     handles edge cases including empty inputs, single components,
    %     and a number_cc greater than the number of components present.

    methods (TestClassSetup)
        function addSourceToPath(tc)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(root);
            tc.addTeardown(@() rmpath(root));
        end
    end

    methods (Test)

        function keepsLargestOf2D(tc)
            % One big component (25 px) and one small (4 px).
            img = false(10, 10);
            img(1:5, 1:5) = true;     % 25 px
            img(8:9, 8:9) = true;     %  4 px
            expected = false(10, 10);
            expected(1:5, 1:5) = true;

            actual = petraToCT.tools.getLargestCC(img);

            tc.verifyEqual(actual, expected);
        end

        function keepsLargestOf3D(tc)
            % Big cube (27 vox) and small cube (8 vox).
            img = false(10, 10, 10);
            img(1:3, 1:3, 1:3) = true;     % 27
            img(8:9, 8:9, 8:9) = true;     %  8
            expected = false(10, 10, 10);
            expected(1:3, 1:3, 1:3) = true;

            actual = petraToCT.tools.getLargestCC(img);

            tc.verifyEqual(actual, expected);
        end

        function keepsTopNComponents(tc)
            % Three disjoint blobs of sizes 16, 9, 4. Keep top 2.
            img = false(20, 20);
            img(1:4,   1:4)   = true;   % 16
            img(1:3,   10:12) = true;   %  9
            img(10:11, 1:2)   = true;   %  4
            expected = false(20, 20);
            expected(1:4,   1:4)   = true;
            expected(1:3,   10:12) = true;

            actual = petraToCT.tools.getLargestCC(img, 2);

            tc.verifyEqual(actual, expected);
        end

        function numberCCGreaterThanPresent(tc)
            % Asking for 5 components when only 2 exist returns both.
            img = false(10, 10);
            img(1:3, 1:3) = true;
            img(8:9, 8:9) = true;

            actual = petraToCT.tools.getLargestCC(img, 5);

            tc.verifyEqual(actual, img);
        end

        function emptyInputReturnsEmpty(tc)
            img = false(10, 10, 10);

            actual = petraToCT.tools.getLargestCC(img);

            tc.verifyEqual(actual, img);
        end

        function singleComponentUnchanged(tc)
            img = false(10, 10);
            img(3:7, 3:7) = true;

            actual = petraToCT.tools.getLargestCC(img);

            tc.verifyEqual(actual, img);
        end

        function preservesSizeAndClass(tc)
            img = false(7, 11, 5);
            img(2:4, 2:4, 2:4) = true;

            actual = petraToCT.tools.getLargestCC(img);

            tc.verifySize(actual, size(img));
            tc.verifyClass(actual, 'logical');
        end

    end

end
