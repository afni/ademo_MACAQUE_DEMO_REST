#!/bin/tcsh

# AP: run afni_proc.py to process resting state FMRI for an ROI-based study.

# This script runs a corresponding do_*.tcsh script, for a given
# subj+ses pair.  It could be adapted to loop over many subj+ses values.

# To execute:  
#     tcsh RUN_SCRIPT_NAME

# --------------------------------------------------------------------------

# specify script to execute
set cmd           = 22_ap_roi

# upper directories
set dir_scr       = $PWD
set dir_inroot    = ${PWD:h}
set dir_basic     = ${dir_inroot}/data_00_basic
set dir_log       = ${dir_inroot}/logs
set dir_swarm     = ${dir_inroot}/swarm 

# running 
set scr_swarm     = ${dir_swarm}/swarm_${cmd}.tcsh  # cmds to run, 1 per line
set scr           = ${dir_scr}/do_${cmd}.tcsh       # processing scr to use

# --------------------------------------------------------------------------

# make directory for storing text files to log the processing
\mkdir -p ${dir_log}
\mkdir -p ${dir_swarm}

# clear away older warm/cmd script, if it exists
if ( -e ${scr_swarm} ) then
    \rm ${scr_swarm}
endif

# --------------------------------------------------------------------------

# Make list of subj to proc; could be done many ways (e.g., direct list)
cd ${dir_basic}
set all_subj = ( sub-* )
cd -

echo ""
echo "++ Proc command:  ${cmd}"
echo ""
echo "++ Found ${#all_subj} subj:"
echo ""

# 1) loop over all subjs, and build a 'swarm' script to run each cmd
# 2) proc each ses separately: assume each session has own anat and func
foreach subj ( ${all_subj} ) 

    # list all ses per subj
    cd ${dir_basic}/${subj}
    set all_ses = ( ses-* )
    cd -

    foreach ses ( ${all_ses} )

        echo "++ Prepare cmd for:  ${subj} --- ${ses}"

        set log = ${dir_log}/log_${cmd}_${subj}_${ses}.txt

        # Build 'swarm' script ('-x' for verbosity; don't use '-e').
        # Make log with 'tee'.
        echo "time tcsh -xf ${scr}  ${subj} ${ses} \\"   >> ${scr_swarm}
        echo "       |& tee ${log}"                      >> ${scr_swarm}

    end
end

# --------------------------------------------------------------------

# return to script dir and execute 'swarm' script
cd ${dir_scr}

echo "++ Executing 'swarm' cmd script: ${scr_swarm}"

tcsh ${scr_swarm}
