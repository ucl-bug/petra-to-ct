classdef toolsFillSmallHolesTest < matlab.unittest.TestCase
    %TOOLSFILLSMALLHOLESTEST Unit tests for petraToCT.tools.fillSmallHoles.
    %
    % DESCRIPTION:
    %     Verifies that fillSmallHoles fills enclosed holes whose voxel
    %     count is at most ceil(radius2measure(MaximumHoleRadius, 3)) and
    %     leaves larger holes intact. Also exercises the intra-package
    %     call into petraToCT.tools.radius2measure to guard against
    %     package-resolution regressions. The function uses a 3-D sphere
    %     structuring element internally, so tests use 3-D inputs to
    %     match the real use in segmentationSPM.

    methods (TestClassSetup)
        function addSourceToPath(tc)
            addpath(getSourceRoot());
            tc.addTeardown(@() rmpath(getSourceRoot()));
        end
    end

    methods (Test)

        function fillsSmallHoleLeavesLargeHole(tc)
            % Solid block with two cubic holes:
            %   small = 4^3 =  64 voxels (post-close: 2^3 = 8)
            %   large = 8^3 = 512 voxels (post-close: 6^3 = 216)
            % MaximumHoleRadius = 3 → sphere-volume threshold =
            % ceil(4*pi*27/3) = 114 vox. 8 < 114 → filled; 216 > 114 →
            % preserved.
            img = false(40, 40, 40);
            img(5:35, 5:35, 5:35) = true;
            img(10:13, 10:13, 10:13) = false;    % small hole
            img(22:29, 22:29, 22:29) = false;    % large hole

            actual = petraToCT.tools.fillSmallHoles(img, ...
                MaximumHoleRadius=3);

            % Sample well inside each original hole, away from the
            % 1-voxel rim that imclose will have moved.
            tc.verifyTrue(all(actual(11:12, 11:12, 11:12), 'all'), ...
                'Small hole interior should be filled.');
            tc.verifyTrue(all(~actual(24:27, 24:27, 24:27), 'all'), ...
                'Large hole interior should remain empty.');
        end

        function isIdempotent(tc)
            img = false(40, 40, 40);
            img(5:35, 5:35, 5:35) = true;
            img(10:13, 10:13, 10:13) = false;

            once  = petraToCT.tools.fillSmallHoles(img,  MaximumHoleRadius=3);
            twice = petraToCT.tools.fillSmallHoles(once, MaximumHoleRadius=3);

            tc.verifyEqual(twice, once);
        end

        function solidInputUnchangedInInterior(tc)
            % A convex, isolated block is unchanged by imclose (identity
            % in the interior) and has no holes, so the function is a
            % no-op here. Allow a 1-voxel boundary for the closing op and
            % compare interiors only.
            img = false(30, 30, 30);
            img(8:22, 8:22, 8:22) = true;

            actual = petraToCT.tools.fillSmallHoles(img);

            interior = false(30, 30, 30);
            interior(9:21, 9:21, 9:21) = true;
            tc.verifyEqual(actual(interior), img(interior));
        end

        function preservesSizeAndClass(tc)
            img = false(12, 18, 10);
            img(3:8, 3:8, 3:7) = true;

            actual = petraToCT.tools.fillSmallHoles(img);

            tc.verifySize(actual, size(img));
            tc.verifyClass(actual, 'logical');
        end

    end

end
