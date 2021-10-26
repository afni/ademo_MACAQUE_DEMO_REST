#!/bin/tcsh

# AP: run afni_proc.py to process the resting state FMRI time series
# for voxelwise study

# Process a single subj+ses pair.  Run this script in
# MACAQUE_DEMO_REST/scripts/, via the corresponding run_*tcsh script.

# ---------------------------------------------------------------------------
# top level definitions (constant across demo)
# ---------------------------------------------------------------------------
 
# labels
set subj           = $1
set ses            = $2

# upper directories
set dir_inroot     = ${PWD:h}                        # one dir above scripts/
set dir_log        = ${dir_inroot}/logs
set dir_ref        = ${dir_inroot}/NMT_v2.1_sym/NMT_v2.1_sym_05mm

set dir_basic      = ${dir_inroot}/data_00_basic
set dir_aw         = ${dir_inroot}/data_13_aw

set dir_ap_vox     = ${dir_inroot}/data_20_ap_vox
set dir_ap_roi     = ${dir_inroot}/data_22_ap_roi

# subject directories
set sdir_basic     = ${dir_basic}/${subj}/${ses}
set sdir_anat      = ${sdir_basic}/anat
set sdir_epi       = ${sdir_basic}/func
set sdir_aw        = ${dir_aw}/${subj}/${ses}

set sdir_ap_vox    = ${dir_ap_vox}/${subj}/${ses}
set sdir_ap_roi    = ${dir_ap_roi}/${subj}/${ses}

# --------------------------------------------------------------------------
# data and control variables
# --------------------------------------------------------------------------

# dataset inputs, with abbreviations for each 
set anat_orig    = ${sdir_anat}/${subj}*T1w*.nii.gz
set anat_orig_ab = ${subj}_anat

set ref_base     = ${dir_ref}/NMT_v2.1_sym_05mm_SS.nii.gz
set ref_base_ab  = NMT2

set ref_atl      = ( ${dir_ref}/CHARM_in_NMT_v2.1_sym_05mm.nii.gz     \
                     ${dir_ref}/D99_atlas_in_NMT_v2.1_sym_05mm.nii.gz )
set ref_atl_ab   = ( CHARM D99 )

set ref_seg      = ${dir_ref}/NMT_v2.1_sym_05mm_segmentation.nii.gz
set ref_seg_ab   = SEG

set ref_mask     = ${dir_ref}/NMT_v2.1_sym_05mm_brainmask.nii.gz 
set ref_mask_ab  = MASK


# AP files
set sdir_this_ap  = ${sdir_ap_vox}                # pick AP dir (and cmd)

set dsets_epi     = ( ${sdir_epi}/${subj}*task-rest*.nii.gz )

set anat_cp       = ${sdir_aw}/${anat_orig_ab}_nsu.nii.gz

set dsets_NL_warp = ( ${sdir_aw}/${anat_orig_ab}_warp2std_nsu.nii.gz           \
                    ${sdir_aw}/${anat_orig_ab}_composite_linear_to_template.1D \
                    ${sdir_aw}/${anat_orig_ab}_shft_WARP.nii.gz                )


# control variables
set nt_rm        = 2
set blur_size    = 2.0
set final_dxyz   = 1.25
set cen_motion   = 0.1
set cen_outliers = 0.02


# cost function choice: some subjects have MION, while others don't
if ( "${subj}" == "sub-01" || "${subj}" == "sub-02" || \
     "${subj}" == "sub-03" ) then
    set cost_a2e = "lpa+ZZ"
else
    set cost_a2e = "lpc+ZZ"
endif

# extra align-EPI-to-anat option---some tricky brightness
# inhomogeneities in some EPIs
if ( "${subj}" == "sub-032223" || "${subj}" == "sub-03" || \
     "${subj}" == "sub-032309" ) then
    set aea_extra = "-rigid_body"
else
    set aea_extra = ""
endif

# another align-EPI-to-anat option---some tricky brightness
# inhomogeneities in some EPIs
if ( "${subj}" == "sub-01" || "${subj}" == "sub-03" || \
     "${subj}" == "sub-032309" ) then
    set aea_uni_epi = "no"
else
    set aea_uni_epi = "yes"
endif


# check available N_threads and report what is being used
# + consider using up to 16 threads (alignment programs are parallelized)
# + N_threads may be set elsewhere; to set here, uncomment the following line:
### setenv OMP_NUM_THREADS 8

set nthr_avail = `afni_system_check.py -check_all | \
                      grep "number of CPUs:" | awk '{print $4}'`
set nthr_using = `afni_check_omp`

echo "++ INFO: Using ${nthr_avail} of available ${nthr_using} threads"

setenv AFNI_COMPRESSOR GZIP

# ---------------------------------------------------------------------------
# run programs
# ---------------------------------------------------------------------------

set ap_cmd = ${sdir_this_ap}/ap.cmd.${subj}

\mkdir -p ${sdir_this_ap}

# write AP command to file
cat <<EOF >! ${ap_cmd}
# -----------------------------------------------------------------
# NOTES

# lpa+zz cost func for some macaques who have MION; lpc+zz for the
# others

# The "-anat_uniform_method none" greatly helps the alignment in
# one or two cases, due to the inhomogeneity of brightness in both
# the EPI and anatomicals (in many cases, it doesn't make much of
# a difference, maybe helps slightly)

# using "-giant_move" in align epi anat, because of large rot diff
# between anat and EPI (different session anat)

# choosing *not* to bandpass (keep degrees of freedom)

# for @radial_correlate: use a radius scaled down from size used
# on human brain vol

# specifying output spatial resolution (1.25 mm iso) explicitly,
# because the input datasets have differing spatial res -- and so
# would likely have differing 'default' output spatial res, too,
# otherwise.
 
# The "pythonic" form of HTML review is now run.  It assumes the
# user has Python with matplotlib installed.

# One could set the environment variable OMP_NUM_THREADS in the
# script before running the afni_proc.py command, which would speed
# up some intermediate steps in the script.  The value to set it to
# depends on the number of CPUs (or threads) on your computer; as an
# exmample one could set it (using tcsh syntax for this script) to
# be:
#    setenv OMP_NUM_THREADS 4
# or more, if possible.

# -----------------------------------------------------------------

afni_proc.py                                                                \
    -subj_id                  ${subj}                                       \
    -blocks            tshift align tlrc volreg blur mask scale regress     \
    -dsets                    ${dsets_epi}                                  \
    -copy_anat                ${anat_cp}                                    \
    -anat_has_skull           no                                            \
    -anat_uniform_method      none                                          \
    -radial_correlate_blocks  tcat volreg                                   \
    -radial_correlate_opts    -sphere_rad 14                                \
    -tcat_remove_first_trs    ${nt_rm}                                      \
    -volreg_align_to          MIN_OUTLIER                                   \
    -volreg_align_e2a                                                       \
    -volreg_tlrc_warp                                                       \
    -volreg_warp_dxyz         ${final_dxyz}                                 \
    -volreg_compute_tsnr      yes                                           \
    -align_opts_aea           -cost "${cost_a2e}" -giant_move               \
                              -cmass cmass -feature_size 0.5 ${aea_extra}   \
    -align_unifize_epi        ${aea_uni_epi}                                \
    -tlrc_base                ${ref_base}                                   \
    -tlrc_NL_warp                                                           \
    -tlrc_NL_warped_dsets     ${dsets_NL_warp}                              \
    -blur_size                ${blur_size}                                  \
    -regress_motion_per_run                                                 \
    -regress_apply_mot_types  demean deriv                                  \
    -regress_censor_motion    ${cen_motion}                                 \
    -regress_censor_outliers  ${cen_outliers}                               \
    -regress_est_blur_errts                                                 \
    -regress_est_blur_epits                                                 \
    -regress_run_clustsim     no                                            \
    -html_review_style        pythonic 

EOF

cd ${sdir_this_ap}

# execute AP command to make processing script
tcsh -xef ${ap_cmd} |& tee output.ap.cmd.${subj}

# execute the proc script, saving text info
time tcsh -xef proc.${subj} |& tee output.proc.${subj}

echo "++ FINISHED AP"

exit 0
