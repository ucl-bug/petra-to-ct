classdef toolsRadius2measureTest < matlab.unittest.TestCase
    %TOOLSRADIUS2MEASURETEST Unit tests for petraToCT.tools.radius2measure.
    %
    % DESCRIPTION:
    %     Verifies that radius2measure returns the area of a circle for
    %     dim = 2 and the volume of a sphere for dim = 3 against closed-form
    %     values, and that values of dim outside {2, 3} are rejected by the
    %     input validator.

    methods (TestClassSetup)
        function addSourceToPath(tc)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(root);
            tc.addTeardown(@() rmpath(root));
        end
    end

    methods (Test)

        function unitCircleArea(tc)
            tc.verifyEqual( ...
                petraToCT.tools.radius2measure(1, 2), pi, ...
                'AbsTol', eps);
        end

        function scaledCircleArea(tc)
            tc.verifyEqual( ...
                petraToCT.tools.radius2measure(2, 2), 4 * pi, ...
                'AbsTol', 1e-12);
        end

        function unitSphereVolume(tc)
            tc.verifyEqual( ...
                petraToCT.tools.radius2measure(1, 3), 4 * pi / 3, ...
                'AbsTol', eps);
        end

        function scaledSphereVolume(tc)
            tc.verifyEqual( ...
                petraToCT.tools.radius2measure(3, 3), (4/3) * pi * 27, ...
                'AbsTol', 1e-12);
        end

        function rejectsBadDim(tc)
            tc.verifyError( ...
                @() petraToCT.tools.radius2measure(1, 4), ?MException);
        end

    end

end
