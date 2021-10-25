# PRIME-DE dataset
# from Klink and Roelfsema (Netherlands Institute for Neuroscience, Netherlands)
# sub-032222/ses-007

# data recentered, because (x,y,z) = (0,0,0) had been outside FOV:
# Note that this overwrites the "-dset .." and "-child .." dsets, so
# you might want to make a copy of them first
@Align_Centers                                                              \
    -no_cp                                                                  \
    -base  ../../NMT_v2.0_sym/NMT_v2.0_sym_05mm/NMT_v2.0_sym_05mm_SS.nii.gz \
    -dset  ses-007/anat/sub-032222_ses-007_run_1_T1w.nii.gz                 \
    -child ses-007/func/sub-*.nii.gz

# anatomical converted to short type (save space during processing).
# Because some the values in the anatomical dset are quite large (>
# 2**15), we scale down the volume values before converting, so there
# isn't any badness with large positive values getting mapped to large
# negative ones.
3dcalc                                                                     \
    -overwrite                                                             \
    -a      ses-007/anat/sub-032222_ses-007_run_1_T1w.nii.gz               \
    -expr   'a/10'                                                         \
    -prefix ses-007/anat/sub-032222_ses-007_run_1_T1w.nii.gz               \
    -nscale                                                                \
    -datum  short

