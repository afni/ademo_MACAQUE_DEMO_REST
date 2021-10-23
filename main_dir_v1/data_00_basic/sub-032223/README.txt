PRIME-DE dataset
from Klink and Roelfsema (Netherlands Institute for Neuroscience, Netherlands)
sub-032223/ses-011

data recentered, because (x,y,z) = (0,0,0) had been outside FOV:
# Note that this overwrites the "-dset .." and "-child .." dsets, so
# you might want to make a copy of them first
@Align_Centers                                                         \
    -no_cp                                                             \
    -base  ../../template/NMT_stereo_sym_2.0_SS.nii.gz                 \
    -dset  ses-011/anat/sub-*1_T1w.nii.gz                              \
    -child ses-011/func/sub-*.nii.gz

