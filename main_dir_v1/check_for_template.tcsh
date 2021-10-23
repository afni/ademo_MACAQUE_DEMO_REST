#!/bin/tcsh

# Supplementary script for the MACAQUE_DEMO*s.  We want this
# particular template dataset to be 'generally' findable.
 
set refvol       = NMT_v2.0_sym_05mm_SS.nii.gz
set list_of_vars = ( "AFNI_GLOBAL_SESSION" \
                     "AFNI_SUPP_ATLAS_DIR" \
                     "AFNI_ATLAS_PATH"     \
                     "AFNI_PLUGINPATH" )

# ----------------------------------------------------------------------

set find_list =  `@FindAfniDsetPath \
                    -full_path      \
                    ${refvol}`

if ( "${find_list}" == "" ) then
    
    # binary directory
    set bin_dir   = `which afni` 
    cd ${bin_dir:h}
    set bin_dir = ${PWD}
    cd -

cat <<EOF
---------------------------------------------------------------------
** Need a copy of the template in a general location.  Please put a copy of:
     NMT_v2.0_sym/NMT_v2.0_sym_05mm/${refvol}
   into one of these locations:
EOF
    echo "     Existing location of AFNI binaries: ${bin_dir}"

    foreach vv ( $list_of_vars )
        set aaa = `afni -get_processed_env  | grep "${vv}"`
        if ( "$aaa" != "" ) then

            # remove first occurence of the variable in the string (which
            # should be the LHS of assignment
            set bbb = `echo $aaa | sed -E "s/${vv}//"`

            # then remove the equals sign, then remove any colon
            # separating things
            set ccc = `echo $bbb | sed -E "s/=//" | tr ':' ' ' `

            echo "     Existing location of '${vv}': ${ccc}"
        else
            echo "     Could define+use '${vv}' in ~/.afnirc" 
        endif
    end

cat <<EOF

   ... and then please run this again to verify:
          tcsh check_for_template.tcsh

EOF


    exit 1
else
    echo "++ Found template  : ${refvol}"
    echo "   ... in location : ${find_list}"
    exit 0
endif
