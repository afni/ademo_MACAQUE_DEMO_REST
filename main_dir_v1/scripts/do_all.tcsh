#!/bin/tcsh

# The first program run here, @animal_warper (AW), will do the following:
#   + align the anatomical dataset to the specified NMT template
#   + preserve a copy of the warps for future use (in afni_proc.py!)
#   + skull strip the anatomical
#   + map the D99 atlas to the native anatomical space
#   + computes surfaces of the atlas regions in native anatomical space
#   + automatically generate images of intermediate/final steps (see QC subdir)
# Then there is afni_proc.py (AP), which does the full single-subject
# processing, run in two separate ways: first, for ROI-based analysis
# (ergo, no blurring); and second, for voxelwise processing (has
# smoothing).  Some macaques had been anaesthetized, but we motion
# estimates in the regression model, anyways, for all subjects in this
# example demo.
# Finally, in the "post-processing" step, we calculate correlation
# matrices for the data stream that did *not* have any smoothing. This
# involves regridding of the template to final EPI resolution, running
# 3dNetCorr to calculate the matrices and fat_mat2d_plot.py to visual
# them (as vector graphics here, so even the tiny font is readable
# with zooming).
#
# Running all of the above commands assumes that:
#    @Install_NMT -nmt_ver 2.0 -sym sym
# ran successfully at installation time.  If not, you can run it again
# from the directory above this one.
#
# For convenience, you can provide an argument when you run this
# script, and "jump" to a particular stage of processing (this still
# assumes that earlier stages have completed successfully).  The
# subsequent processings (if any) will still be done.  The arguments
# are:
#   
#    aw        = jump to @animal_warper step 
#    ap        = jump to first afni_proc.py case (for ROI-based analysis)
#    apvox     = jump to second afni_proc.py case (for voxelwise analysis)
#    postproc  = jump to correlation matrix generation (ROI-based)
#
# This script can be run via one of the following (latter stops
# running if an error/failure occurs:
#
#    tcsh do_all.tcsh
#    tcsh -ef do_all.tcsh 
# ------------------------------------------------------------------------

cd  ..                                    # full path of template directory
set topdir = ${PWD}
cd  -

set dir_scr    = $PWD                       # scripts directory
set dir_basic  = ${topdir}/data_00_basic    # 
set dir_aw     = ${topdir}/data_01_aw       # AW output
set dir_ap     = ${topdir}/data_02_ap       # AP output for ROI-based
set dir_ap_vox = ${topdir}/data_02_ap_vox   # AP output for voxelwise
set dir_pp     = ${topdir}/data_03_postproc # corr mats for ROI-based proc

# The template + atlas data; more follower datasets could be input.
# Abbreviations are defined for each dset, to simplify naming of files
set refdir    = ${topdir}/NMT_v2.0_sym/NMT_v2.0_sym_05mm
set refvol    = `\ls ${refdir}/NMT*_SS.nii.gz`
set refvol_ab = NMT2
set refatl    = `\ls ${refdir}/CHARM*.nii.gz \
                     ${refdir}/D99*.nii.gz`
set refatl_ab = ( CHARM D99 )
set refseg    = `\ls ${refdir}/NMT*_segmentation*.nii.gz  \
                     ${refdir}/supplemental_masks/NMT*_ventricles*.nii.gz`
set refseg_ab = ( SEG VENT )
set refmask   = `\ls ${refdir}/NMT*_brainmask*.gz`
set refmask_ab = MASK


### user's could set this environment variable here or in the own
### ~/.*rc files: useful if one has multiple CPUs/threads on the OS.
# setenv OMP_NUM_THREADS 12

# -----------------------------------------------------------------

# get list of subj to process
cd ${dir_basic} 
set all_subj = `find . -maxdepth 1 -type d -name "sub*" | cut -b3- | sort`
echo "++ Found these ${#all_subj} subj:"
echo "     ${all_subj}"
cd -

# -----------------------------------------------------------------

# shortcuts to jump to processing steps (AW doesn't *need* one...)
if ( "$1" == "aw" ) then
    echo "++ JUMPING to AW"
    goto JUMP_AW
else if ( "$1" == "ap" ) then
    echo "++ JUMPING to AP"
    goto JUMP_AP
else if ( "$1" == "apvox" ) then
    echo "++ JUMPING to AP_VOX"
    goto JUMP_AP_VOX
else if ( "$1" == "postproc" ) then
    echo "++ JUMPING to 'postproc'"
    goto JUMP_PP
else if ( "$1" != "" ) then
    echo "** ERROR: unrecognized arg for jump: $1"
    exit 1
endif

# -----------------------------------------------------------------

JUMP_AW:

# animal_warper for skullstripping and nonlinear warp estimation

foreach subj ( ${all_subj} )
    
    # get first anat out of any possible ones in basic subj dir--
    # but there is only one anat per subj here
    cd ${dir_basic}/${subj}
    set all_anat = `find . -type f -name "sub*T1w*nii*"`
    cd -
    set anat_subj = "${dir_basic}/${subj}/${all_anat[1]}"
    echo "++ Found anat:"
    echo "     ${anat_subj}"

    set odir_aw = ${dir_aw}/${subj}
    \mkdir -p ${odir_aw}

    @animal_warper                          \
        -echo                               \
        -input            ${anat_subj}      \
        -input_abbrev     ${subj}_anat      \
        -base             ${refvol}         \
        -base_abbrev      ${refvol_ab}      \
        -atlas_followers  ${refatl}         \
        -atlas_abbrevs    ${refatl_ab}      \
        -seg_followers    ${refseg}         \
        -seg_abbrevs      ${refseg_ab}      \
        -skullstrip       ${refmask}        \
        -outdir           ${odir_aw}        \
        -ok_to_exist                        \
        |& tee ${odir_aw}/o.aw_${subj}.txt

end

echo "++ Done with aligning anatomical with template"


# -----------------------------------------------------------------

JUMP_AP:

# afni_proc.py to do full preprocessing


foreach subj ( ${all_subj} )
    
    # get all EPI runs per subj, in the order of acquisition--- there
    # are only 2 runs per subj here
    cd ${dir_basic}/${subj}
    set all_epi = `find . -type f -name "sub*task-rest*run-*nii*" | sort`
    cd -
    echo "++ Found EPIs:"
    echo "     ${all_epi}"

    # need each EPI file to have path attached
    set subj_epi = ( )
    foreach ee ( ${all_epi} )
        set subj_epi = ( ${subj_epi} ${dir_basic}/${subj}/${ee} )
    end

    set odir_aw = ${dir_aw}/${subj}
    set odir_ap = ${dir_ap}/${subj}
    \mkdir -p ${odir_ap}

    # Using the lpa+zz cost func for some macaques who have MION;
    # lpc+zz for the others

    # Using "-giant_move" in align epi anat, because of large rot diff
    # between anat and EPI. 

    # The feature_size=0.5 appears to be very important for a few
    # macaques for EPI-anat alignment;  helps minorly for all.

    # The "-anat_uniform_method none" greatly helped the alignment in
    # one or two cases, due to the inhomogeneity of brightness in both
    # the EPI and anatomicals (in many cases, it doesn't make much of
    # a difference, maybe helps slightly)

    # Choosing *not* to bandpass (keep degrees of freedom).

    # For @radial_correlate: use a radius scaled down from size used
    # on human brain vol.

    # Specifying output spatial resolution (1.25 mm iso) explicitly,
    # because the input datasets have differing spatial res -- and so
    # would likely have differing 'default' output spatial res, too,
    # otherwise.

    set dset_subj_anat = `\ls ${odir_aw}/${subj}*_ns.* | grep -v "_warp2std"`

    if ( "${subj}" == "sub-01" || "${subj}" == "sub-02" || \
         "${subj}" == "sub-03" ) then
         set cost_a2e = "lpa+zz"
    else
        set cost_a2e = "lpc+zz"
    endif


    afni_proc.py                                                              \
        -subj_id                 ${subj}                                      \
        -script                  ${odir_ap}/proc.$subj -scr_overwrite         \
        -out_dir                 ${odir_ap}/${subj}.results                   \
        -blocks tshift align tlrc volreg mask scale regress                   \
        -dsets                   ${subj_epi}                                  \
        -copy_anat               "${dset_subj_anat}"                          \
        -anat_has_skull          no                                           \
        -anat_uniform_method     none                                         \
        -radial_correlate_blocks tcat volreg                                  \
        -radial_correlate_opts   -sphere_rad 14                               \
        -tcat_remove_first_trs   2                                            \
        -volreg_align_to         MIN_OUTLIER                                  \
        -volreg_align_e2a                                                     \
        -volreg_tlrc_warp                                                     \
        -volreg_warp_dxyz        1.25                                         \
        -align_opts_aea          -cost ${cost_a2e} -giant_move                \
                                 -cmass cmass -feature_size 0.5               \
        -tlrc_base               ${refvol}                                    \
        -tlrc_NL_warp                                                         \
        -tlrc_NL_warped_dsets                                                 \
            ${odir_aw}/${subj}*_warp2std_nsu.nii.gz                           \
            ${odir_aw}/${subj}*_composite_linear_to_template.1D               \
            ${odir_aw}/${subj}*_shft_WARP.nii.gz                              \
        -regress_motion_per_run                                               \
        -regress_apply_mot_types  demean deriv                                \
        -regress_censor_motion    0.10                                        \
        -regress_censor_outliers  0.02                                        \
        -regress_est_blur_errts                                               \
        -regress_est_blur_epits                                               \
        -regress_run_clustsim     no                                          \
        -html_review_style        pythonic                                    \
        -execute

end

echo "\n\n++ DONE.\n\n"

# -----------------------------------------------------------------

JUMP_AP_VOX:

# afni_proc.py to do full preprocessing, for voxelwise (has smoothing)


foreach subj ( ${all_subj} )
    
    # get all EPI runs per subj, in the order of acquisition--- there
    # are only 2 runs per subj here
    cd ${dir_basic}/${subj}
    set all_epi = `find . -type f -name "sub*task-rest*run-*nii*" | sort`
    cd -
    echo "++ Found EPIs:"
    echo "     ${all_epi}"

    # need each EPI file to have path attached
    set subj_epi = ( )
    foreach ee ( ${all_epi} )
        set subj_epi = ( ${subj_epi} ${dir_basic}/${subj}/${ee} )
    end

    set odir_aw = ${dir_aw}/${subj}
    # Note this is in the 'vox' one
    set odir_ap = ${dir_ap_vox}/${subj}
    \mkdir -p ${odir_ap}

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

    # get some tissue maps that are native space for anaticor (use the
    # final, modally smoothed ones); need to extra WM from segmentation
    set dset_subj_anat = `\ls ${odir_aw}/${subj}*_ns.* | grep -v "_warp2std"`

    if ( "${subj}" == "sub-01" || "${subj}" == "sub-02" || \
         "${subj}" == "sub-03" ) then
         set cost_a2e = "lpa+zz"
    else
        set cost_a2e = "lpc+zz"
    endif

    afni_proc.py                                                              \
        -subj_id                 ${subj}                                      \
        -script                  ${odir_ap}/proc.$subj -scr_overwrite         \
        -out_dir                 ${odir_ap}/${subj}.results                   \
        -blocks tshift align tlrc volreg blur mask scale regress              \
        -dsets                   ${subj_epi}                                  \
        -copy_anat               "${dset_subj_anat}"                          \
        -anat_has_skull          no                                           \
        -anat_uniform_method     none                                         \
        -radial_correlate_blocks tcat volreg                                  \
        -radial_correlate_opts   -sphere_rad 14                               \
        -tcat_remove_first_trs   2                                            \
        -volreg_align_to         MIN_OUTLIER                                  \
        -volreg_align_e2a                                                     \
        -volreg_tlrc_warp                                                     \
        -volreg_warp_dxyz        1.25                                         \
        -blur_size                2.0                                         \
        -align_opts_aea          -cost ${cost_a2e} -giant_move                \
                                 -cmass cmass -feature_size 0.5               \
        -tlrc_base               ${refvol}                                    \
        -tlrc_NL_warp                                                         \
        -tlrc_NL_warped_dsets                                                 \
            ${odir_aw}/${subj}*_warp2std_nsu.nii.gz                           \
            ${odir_aw}/${subj}*_composite_linear_to_template.1D               \
            ${odir_aw}/${subj}*_shft_WARP.nii.gz                              \
        -regress_motion_per_run                                               \
        -regress_apply_mot_types  demean deriv                                \
        -regress_censor_motion    0.10                                        \
        -regress_censor_outliers  0.02                                        \
        -regress_est_blur_errts                                               \
        -regress_est_blur_epits                                               \
        -regress_run_clustsim     no                                          \
        -html_review_style        pythonic                                    \
        -execute

end

echo "\n\n++ DONE.\n\n"

# -----------------------------------------------------------------

JUMP_PP:

# 'Postprocessing' after the AP preproc for ROI-based analysis; here,
# just func correlation matrices

foreach subj ( ${all_subj} )
    
    # ${dir_ap} is for ROI-based analysis
    set odir_apr = ${dir_ap}/${subj}/${subj}.results # has AP results
    set odir_pp  = ${dir_pp}/${subj}                 # for postproc
    \mkdir -p ${odir_pp}

    # should just be one time series of residuals
    set errts    = `\ls ${dir_ap}/${subj}/${subj}.results/errts*HEAD`

    # resample each standard space atlas to final EPI resolution
    foreach ff ( ${refatl} ) 

        # uppermost brick index in atlas dset
        set nvi     = `3dinfo -nvi ${ff}`

        set opref   = ${subj}_epi_`basename ${ff}`
        set epi_atl = ${odir_pp}/${opref}

        3dresample -echo_edu                      \
            -overwrite                            \
            -input         "${ff}"                \
            -rmode          NN                    \
            -master         ${errts}              \
            -prefix         ${epi_atl}

        # reattach any labels/atlases
        3drefit -copytables "${ff}" ${epi_atl}
        3drefit -cmap INT_CMAP      ${epi_atl}

        set ooo     = `3dinfo -prefix_noext ${epi_atl}`
        set onet    = ${odir_pp}/${ooo}

        3dNetCorr -echo_edu                         \
            -overwrite                              \
            -fish_z                                 \
            -inset   ${errts}                       \
            -in_rois ${epi_atl}                     \
            -prefix  ${onet}

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
end

exit 0 


