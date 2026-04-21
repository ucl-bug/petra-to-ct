classdef segmentationSPMIntegrationTest < matlab.unittest.TestCase
    %SEGMENTATIONSPMINTEGRATIONTEST End-to-end test for petraToCT.segmentationSPM.
    %
    % DESCRIPTION:
    %     Runs the SPM unified segmentation plus morphological
    %     post-processing on the small PETRA fixture, and verifies that
    %     the expected friendly-named segmentation files are written and
    %     that the returned masks have the correct shape and contain
    %     non-trivial content. Filtered when SPM or the fixture is not
    %     available. Slow — SPM segmentation typically takes minutes.

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

        function segmentsPetraFixture(tc)
            % SPM segmentation is expensive (~15 min on the fixture), so
            % this single test runs it once and asserts several things:
            %   - the friendly-named output NIfTIs are written (SPM
            %     writes c1..c6 and segmentationSPM renames bone and
            %     soft-tissue — catches regressions in the rename),
            %   - the returned masks have equal shape and contain a
            %     non-trivial number of voxels,
            %   - the skull mask is (approximately) a subset of the head
            %     mask.
            localInput = fullfile(tc.WorkDir, 'petra.nii.gz');
            copyfile(tc.InputFile, localInput);

            [headMask, skullMask] = petraToCT.segmentationSPM(localInput, ...
                MaskPlot=false, ...
                OutputDir=tc.WorkDir);

            tc.verifyTrue(exist(fullfile(tc.WorkDir, ...
                'spm_soft_tissue_seg.nii'), 'file') == 2, ...
                'spm_soft_tissue_seg.nii should be written.');
            tc.verifyTrue(exist(fullfile(tc.WorkDir, ...
                'spm_bone_seg.nii'), 'file') == 2, ...
                'spm_bone_seg.nii should be written.');

            tc.verifyEqual(size(headMask), size(skullMask), ...
                'Head and skull masks should share the input volume shape.');
            tc.verifyGreaterThan(nnz(headMask), 0, ...
                'Head mask should contain some voxels.');
            tc.verifyGreaterThan(nnz(skullMask), 0, ...
                'Skull mask should contain some voxels.');

            overlap = nnz(skullMask & headMask) / nnz(skullMask);
            tc.verifyGreaterThan(overlap, 0.95, ...
                'Skull mask should be (approximately) a subset of head mask.');
        end

    end

end
