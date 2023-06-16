# PETRA-TO-CT

## Overview

MATLAB toolbox for converting a PETRA image to a pseudo-CT.

## Setup

The following dependencies must first be installed:

- [3D Slicer ](https://www.slicer.org/)
- SPM12
- [Tools for NIfTI and ANALYZE image](https://uk.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image) (can be installed from the MATLAB add-on explorer)

The following setup steps must be performed

- This toolbox, SPM12, and the NIFTI tools must be added to the MATLAB path.

- 3D Slicer must be added to the system path (see notes in `debias.m`).

## Usage

Convert a PETRA image to a pseudo-CT:

```matlab
petraToCT.convert('myImage.nii');
```

Convert, keeping the SPM segmentation:

```matlab
petraToCT.convert('myImage.nii', DeleteSegmentation=false);
```

Convert, reusing an existing SPM segmentation:

```matlab
petraToCT.convert('myImage.nii', RunSegmentation=false);
```





