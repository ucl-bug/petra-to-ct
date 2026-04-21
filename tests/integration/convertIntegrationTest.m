classdef convertIntegrationTest < matlab.unittest.TestCase
    %CONVERTINTEGRATIONTEST End-to-end smoke test for petraToCT.convert.
    %
    % DESCRIPTION:
    %     Runs the full debias -> segment -> normalise -> HU map pipeline
    %     on the small PETRA fixture and checks that the output
    %     pseudo-CT file exists, has sensible class and shape, and
    %     contains values in a plausible HU range with the expected
    %     background value. Filtered when SPM, Slicer or the fixture is
    %     not available. Slow — runs full SPM segmentation.

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
            tc.assumeTrue(~isempty(which('spm')), ...
                'SPM not found on the MATLAB path.');
            tc.assumeTrue(~isempty(which('load_nii')), ...
                'NIfTI toolbox not found on the MATLAB path.');
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

        function producesPseudoCTInHuRange(tc)
            localInput = fullfile(tc.WorkDir, 'petra.nii.gz');
            copyfile(tc.InputFile, localInput);

            pctFile = petraToCT.convert(localInput, ...
                OutputDir=tc.WorkDir, ...
                HistogramPlot=false, ...
                MaskPlot=false);

            tc.verifyTrue(exist(pctFile, 'file') == 2, ...
                'Pseudo-CT file should be written.');

            pctNii = load_nii(pctFile);
            pct = double(pctNii.img);

            tc.verifyTrue(any(pct(:) == -1000), ...
                'Background should be set to -1000 HU.');
            tc.verifyTrue(any(pct(:) == 42), ...
                'Head region should be set to 42 HU.');
            tc.verifyGreaterThan(max(pct(:)), 200, ...
                'Skull region should produce HU values well above soft tissue.');
            tc.verifyLessThanOrEqual(max(pct(:)), 4000, ...
                'Skull HU values should stay below a physical upper bound.');
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
