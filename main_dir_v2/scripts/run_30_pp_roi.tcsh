#!/bin/tcsh

# PP: post-processing with 3dNetCorr and some other supplementary
# progs for ROI-based calcs

# This script runs a corresponding do_*.tcsh script, for a given
# subj+ses pair.  It could be adapted to loop over many subj+ses values.

# To execute:  
#     tcsh RUN_SCRIPT_NAME

# --------------------------------------------------------------------------

# specify script to execute
set cmd           = 30_pp_roi

# upper directories
set dir_scr       = $PWD
set dir_inroot    = ${PWD:h}
set dir_basic     = ${dir_inroot}/data_00_basic
set dir_log       = ${dir_inroot}/logs
set dir_swarm     = ${dir_inroot}/swarm 

# running 
set scr_swarm     = ${dir_swarm}/swarm_${cmd}.tcsh

# --------------------------------------------------------------------------

# make directory for storing text files to log the processing
\mkdir -p ${dir_log}
\mkdir -p ${dir_swarm}

# clear away older warm/cmd script, if it exists
if ( -e ${scr_swarm} ) then
    \rm ${scr_swarm}
endif

# --------------------------------------------------------------------------

# make list of subject IDs, could be done in various ways (e.g., just
# a directly-made array of IDs):
### set all_subj = ( sub-01 sub-02 sub-03 sub-032222 sub-032223 sub-032309 )
cd ${dir_basic}
set all_subj = `find ./ -maxdepth 1 -type d | cut -b3- | sort`
cd -

echo ""
echo "++ Proc command:  ${cmd}"
echo ""
echo "++ Found ${#all_subj} subj:"
echo "   ${all_subj}"
echo ""

# loop over all subjs, and build script to run each cmd
foreach subj ( ${all_subj} ) 

    # For each subject, get name of session directory.  There should
    # only be 1 per subj, for the way this is presently scripted
    cd ${dir_basic}/${subj}
    set ses = `find . -maxdepth 1 -type d -name "ses*" | cut -b3-`
    cd -

    if ( "${#ses}" != "1" ) then
        echo "** ERROR: supposed to have exactly 1 ses per subj,"
        echo "   but subj '${subj}' has ${#ses} session dirs."
        exit 1
    endif

# Put that subj into 'swarm' script (verbosely, and don't use '-e'),
# and use 'tee' to log terminal text.  Do NOT indent the next section
# between cat << EOF ... EOF
cat << EOF >> ${scr_swarm}
time tcsh -xf ${dir_scr}/do_${cmd}.tcsh  ${subj}  ${ses}          \
       |& tee ${dir_log}/log_${cmd}_${subj}_${ses}.txt
EOF

end

# --------------------------------------------------------------------

# return to script dir and execute 'swarm' script
cd ${dir_scr}

echo "++ Executing cmd script: ${scr_swarm}"

tcsh ${scr_swarm}
