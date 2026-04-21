classdef toolsFillAllHolesTest < matlab.unittest.TestCase
    %TOOLSFILLALLHOLESTEST Unit tests for petraToCT.tools.fillAllHoles.
    %
    % DESCRIPTION:
    %     Verifies that fillAllHoles fills enclosed holes in 2D and 3D
    %     binary images, preserves solid convex shapes that are padded
    %     away from the array boundary (morphological closing is identity
    %     in this regime), is idempotent, and respects the dims argument
    %     that restricts the 2D-plane sweep direction.

    methods (TestClassSetup)
        function addSourceToPath(tc)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(root);
            tc.addTeardown(@() rmpath(root));
        end
    end

    methods (Test)

        function fillsHollow3DShell(tc)
            % A cube shell with a fully enclosed cavity should come out
            % solid after closing + plane-sweep fill.
            img = false(30, 30, 30);
            img(10:20, 10:20, 10:20) = true;   % solid cube
            img(13:17, 13:17, 13:17) = false;  % interior cavity

            expected = false(30, 30, 30);
            expected(10:20, 10:20, 10:20) = true;

            actual = petraToCT.tools.fillAllHoles(img, 3, [1, 2, 3]);

            tc.verifyEqual(actual, expected);
        end

        function preservesSolid3DCube(tc)
            % Morphological closing of a convex shape far from the array
            % boundary is the identity.
            img = false(30, 30, 30);
            img(10:20, 10:20, 10:20) = true;

            actual = petraToCT.tools.fillAllHoles(img, 3, [1, 2, 3]);

            tc.verifyEqual(actual, img);
        end

        function isIdempotent3D(tc)
            img = false(30, 30, 30);
            img(10:20, 10:20, 10:20) = true;
            img(13:17, 13:17, 13:17) = false;

            once  = petraToCT.tools.fillAllHoles(img,  3, [1, 2, 3]);
            twice = petraToCT.tools.fillAllHoles(once, 3, [1, 2, 3]);

            tc.verifyEqual(twice, once);
        end

        function sweepDimensionChangesResult(tc)
            % A z-aligned tube with both end caps open cannot be fully
            % filled by any sweep (imfill sees the interior as connected
            % to the z-boundary), but sweeping all three axes fills more
            % voxels than sweeping one, because the dilation step thickens
            % the walls into the interior and later sweeps pick up the
            % resulting pockets that a single-axis sweep misses.
            img = false(30, 30, 30);
            img(10:20, 10:20, :) = true;
            img(13:17, 13:17, :) = false;

            interior = false(30, 30, 30);
            interior(13:17, 13:17, :) = true;

            sweepX   = petraToCT.tools.fillAllHoles(img, 1, 1);
            sweepAll = petraToCT.tools.fillAllHoles(img, 1, [1, 2, 3]);

            tc.verifyGreaterThan(nnz(sweepAll(interior)), ...
                                 nnz(sweepX(interior)), ...
                'Sweeping all axes should fill more of the tube interior than sweeping one axis.');
        end

        function fillsHollowDisk2D(tc)
            % 2D annulus. The function's per-axis sweep degrades to 1-D
            % imfill when called on a 2-D array with dims spanning both
            % in-plane axes, so use dims = 3 which keeps the imfill call
            % on the full 2-D slice.
            [X, Y] = ndgrid(1:30, 1:30);
            r = sqrt((X - 15).^2 + (Y - 15).^2);
            img = (r >= 6) & (r <= 8);

            actual = petraToCT.tools.fillAllHoles(img, 1, 3);

            tc.verifyTrue(all(actual(r <= 5), 'all'), ...
                'Interior should be filled.');
            tc.verifyTrue(all(~actual(r > 9), 'all'), ...
                'Result should stay within a 1-voxel dilation of the disk.');
            tc.verifyClass(actual, 'logical');
            tc.verifySize(actual, size(img));
        end

        function preservesSizeAndClass(tc)
            img = false(15, 25, 10);
            img(5:10, 10:15, 3:7) = true;

            actual = petraToCT.tools.fillAllHoles(img, 2, [1, 2, 3]);

            tc.verifySize(actual, size(img));
            tc.verifyClass(actual, 'logical');
        end

    end

end
