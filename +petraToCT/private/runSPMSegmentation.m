function runSPMSegmentation(inputFilename, outputDir)
%RUNSPMSEGMENTATION Run SPM segmentation.
%
% DESCRIPTION:
%     runSPMSegmentation segments an input image using SPM. SPM must be
%     installed and on the MATLAB path. The output images are stored in the
%     same path as the input image.
%
% USAGE:
%     runSPMSegmentation(inputFilename)
%
% INPUTS:
%     inputFilename - Pathname / filename for input image in nifti format.
%     outputDir     - Directory for saving SPM images.

% Copyright (C) 2023- University College London (Bradley Treeby).

arguments
    inputFilename 
    outputDir = []
end

% Get path to SPM.
spmPath = fileparts(which('spm'));

% Setup options.
matlabbatch{1}.spm.spatial.preproc.channel.vols = {[inputFilename ',1']};
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];

% Debiasing.
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.0001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 20;

% Grey matter (off).
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[spmPath '\tpm\TPM.nii,1']};
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];

% White matter (off).
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[spmPath '\tpm\TPM.nii,2']};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];

% CSF (off).
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[spmPath '\tpm\TPM.nii,3']};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];

% Bone.
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[spmPath '\tpm\TPM.nii,4']};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];

% Soft tissue.
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[spmPath '\tpm\TPM.nii,5']};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];

% Air background.
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[spmPath '\tpm\TPM.nii,6']};
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];

% Processing options.
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;                         % MRF smoothing.
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 2;                     % Post-proc cleanup [0-2].
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];    % Regularization parameters for warp.
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';                  % Affine registration target.
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;                        % Smoothing.
matlabbatch{1}.spm.spatial.preproc.warp.samp = 2;                        % Sampling distance.
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];                   % Don't save deformation fields.
matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;                       % Keep original image resolution.
matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN; NaN NaN NaN]; % Bounding box.

% Run segmentation.
spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch);

% Move output images.
if ~isempty(outputDir)

    [inputDir, inputName, inputExt] = fileparts(inputFilename);
    
    % Create output directory if it doesn't exist
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    
    % Define output files
    outputFiles = {
        ['c4' inputName inputExt], 'spm_bone_seg.nii';
        ['c5' inputName inputExt], 'spm_soft_tissue_seg.nii';
        ['c6' inputName inputExt], 'spm_background_seg.nii';
        [inputName '_seg8.mat'], 'spm_seg8.mat';
    };
    
    % Move and rename each file
    for i = 1:size(outputFiles, 1)
        oldFile = fullfile(inputDir, outputFiles{i, 1});
        newFile = fullfile(outputDir, outputFiles{i, 2});
        
        if exist(oldFile, 'file')
            movefile(oldFile, newFile);
        end
    end

end
