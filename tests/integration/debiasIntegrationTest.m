classdef debiasIntegrationTest < matlab.unittest.TestCase
    %DEBIASINTEGRATIONTEST End-to-end test for petraToCT.debias.
    %
    % DESCRIPTION:
    %     Runs N4ITK bias correction (via 3D Slicer) on the small PETRA
    %     fixture and checks that an output NIfTI is written with
    %     sensible properties. Filtered when Slicer or the fixture is not
    %     available.

    properties (TestParameter)
    end

    properties
        InputFile
        WorkDir
    end

    methods (TestClassSetup)
        function addSourceToPath(tc)
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            addpath(root);
            tc.addTeardown(@() rmpath(root));
        end

        function checkPrerequisites(tc)
            fixture = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
                'fixtures', 'petra.nii.gz');
            tc.assumeTrue(exist(fixture, 'file') == 2, ...
                sprintf('PETRA fixture not found at %s.', fixture));
            tc.assumeTrue(hasSlicer(), ...
                'Slicer / N4ITKBiasFieldCorrection not found on this system.');
            tc.InputFile = fixture;
        end
    end

    methods (TestMethodSetup)
        function makeWorkDir(tc)
            tc.WorkDir = tempname;
            mkdir(tc.WorkDir);
            tc.addTeardown(@() rmdir(tc.WorkDir, 's'));
        end
    end

    methods (Test)

        function producesOutputFile(tc)
            outFile = fullfile(tc.WorkDir, 'petra-debiased.nii.gz');

            petraToCT.debias(tc.InputFile, outFile);

            tc.verifyTrue(exist(outFile, 'file') == 2, ...
                'debias should write the requested output file.');
            info = dir(outFile);
            tc.verifyGreaterThan(info.bytes, 0, ...
                'Output file should not be empty.');
        end

        function autoNamesOutputWhenOmitted(tc)
            % Copy fixture into WorkDir so the auto-named output lands
            % alongside it rather than in the repo fixtures folder.
            localInput = fullfile(tc.WorkDir, 'petra.nii.gz');
            copyfile(tc.InputFile, localInput);

            outFile = petraToCT.debias(localInput);

            tc.verifyTrue(exist(outFile, 'file') == 2);
            tc.verifyTrue(endsWith(outFile, '-debiased.nii.gz'), ...
                'Auto-named output should end with -debiased.nii.gz.');
        end

    end

end

function tf = hasSlicer()
    if ismac
        tf = exist('/Applications/Slicer.app', 'dir') == 7;
    else
        [status, ~] = system('which Slicer');
        tf = status == 0;
    end
end
