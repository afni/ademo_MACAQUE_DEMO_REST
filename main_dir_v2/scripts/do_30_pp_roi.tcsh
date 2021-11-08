#!/bin/tcsh

# PP: post-proc with 3dNetCorr et al. for ROI-based calcs

# Process a single subj+ses pair.  Run this script in
# MACAQUE_DEMO_REST/scripts/, via the corresponding run_*tcsh script.

# ---------------------------------------------------------------------------
# top level definitions (constant across demo)
# ---------------------------------------------------------------------------
 
# labels
set subj           = $1
set ses            = $2
set ap_label       = 22_ap_roi
set pp_label       = 30_pp_roi

# upper directories
set dir_inroot     = ${PWD:h}                        # one dir above scripts/
set dir_log        = ${dir_inroot}/logs
set dir_ref        = ${dir_inroot}/NMT_v2.1_sym/NMT_v2.1_sym_05mm

set dir_basic      = ${dir_inroot}/data_00_basic
set dir_aw         = ${dir_inroot}/data_13_aw
set dir_ap         = ${dir_inroot}/data_${ap_label}
set dir_pp         = ${dir_inroot}/data_${pp_label}

# subject directories
set sdir_basic     = ${dir_basic}/${subj}/${ses}
set sdir_anat      = ${sdir_basic}/anat
set sdir_epi       = ${sdir_basic}/func
set sdir_aw        = ${dir_aw}/${subj}/${ses}
set sdir_ap        = ${dir_ap}/${subj}/${ses}
set sdir_pp        = ${dir_pp}/${subj}/${ses}

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
set dsets_epi     = ( ${sdir_epi}/${subj}*task-rest*.nii.gz )

set anat_cp       = ${sdir_aw}/${anat_orig_ab}_nsu.nii.gz

set dsets_NL_warp = ( ${sdir_aw}/${anat_orig_ab}_warp2std_nsu.nii.gz           \
                    ${sdir_aw}/${anat_orig_ab}_composite_linear_to_template.1D \
                    ${sdir_aw}/${anat_orig_ab}_shft_WARP.nii.gz                )


# control variables
# + NO smoothing here, because ROI-based proc
set nt_rm        = 2
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

\mkdir -p ${sdir_pp}

# cp residual time series from AP results dir; after, use ${errts}
set edset = ( ${sdir_ap}/${subj}.results/errts*HEAD )
set epref = `3dinfo -prefix_noext "${edset}"`
set errts = ${sdir_pp}/${epref}.nii.gz
3dcopy                               \
    -overwrite                       \
    ${edset}                         \
    ${errts}


# resample each standard space atlas to final EPI resolution
foreach ff ( ${ref_atl} ) 

    # uppermost brick index in atlas dset
    set nvi     = `3dinfo -nvi ${ff}`

    set opref   = ${subj}_epi_`basename ${ff}`
    set epi_atl = ${sdir_pp}/${opref}

    3dresample -echo_edu                      \
        -overwrite                            \
        -input         "${ff}"                \
        -rmode          NN                    \
        -master         ${errts}              \
        -prefix         ${epi_atl}

    if ( $status ) then
        echo "** ERROR: failed to resample '${ff}' for ${subj}"
        exit 1
    endif

    # reattach any labels/atlases
    3drefit -copytables "${ff}" ${epi_atl}
    3drefit -cmap INT_CMAP      ${epi_atl}

    set ooo     = `3dinfo -prefix_noext ${epi_atl}`
    set onet    = ${sdir_pp}/${ooo}

    # note the use of "-allow_roi_zeros -push_thru_many_zeros":
    # because of the FOV of some dsets, a couple finer ROIs end up
    # being all zeros, and some ROIs fall outside the acquired data
    3dNetCorr -echo_edu                         \
        -overwrite                              \
        -allow_roi_zeros -push_thru_many_zeros  \
        -fish_z                                 \
        -inset   ${errts}                       \
        -in_rois ${epi_atl}                     \
        -prefix  ${onet}

    if ( $status ) then
        echo "** ERROR: failed after 3dNetCorr for ${subj}"
        exit 1
    endif

    foreach ii ( `seq 0 1 ${nvi}` )
        set iii   = `printf "%03d" ${ii}`
        set netcc = ${onet}_${iii}.netcc

        fat_mat2d_plot.py                  \
            -input  ${netcc}               \
            -pars   'CC'                   \
            -vmin  -0.8                    \
            -vmax   0.8                    \
            -cbar   'RdBu_r'               \
            -dpi    100                    \
            -ftype  svg   

    end
end

echo "++ FINISHED PP: ${pp_label}"

exit 0
