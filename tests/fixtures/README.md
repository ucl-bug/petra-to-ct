# Test fixtures

## `petra.nii.gz`

A small, defaced PETRA volume used by the integration tests in `tests/integration`. Derived from a single PETRA acquisition using the following pipeline:

```bash
# Deface the raw scan
mideface --i noT1_petra_tra_FA_1_deg.nii --o petra.nii.gz

# Downsample to 2 mm isotropic to keep the file small enough for git
fslmaths petra.nii.gz -subsamp2 petra.nii.gz
```

The downsampling keeps full-head coverage so SPM unified segmentation still produces sensible tissue masks, while keeping the file to a few MB.
