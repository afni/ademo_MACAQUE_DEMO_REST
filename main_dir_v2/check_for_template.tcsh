#!/bin/tcsh

# Supplementary script for the MACAQUE_DEMO*s.  We want this
# particular template dataset to be 'generally' findable.
 
set refvol       = ( NMT_v2.1_sym_05mm_SS.nii.gz )
set extra_vols   = ( CHARM_in_NMT_v2.1_sym_05mm.nii.gz      \
                     D99_atlas_in_NMT_v2.1_sym_05mm.nii.gz  )
set refloc       = NMT_v2.1_sym/NMT_v2.1_sym_05mm/
                    
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

       ${refloc}/${refvol}

   ... into one of these existing locations:

EOF
    printf "     + %-30s : %s\n" "AFNI binaries dir" "${bin_dir}"

    set all_other = ( )

    foreach vv ( $list_of_vars )
        set aaa = `afni -get_processed_env  | grep "${vv}"`
        if ( "$aaa" != "" ) then

            # remove first occurence of the variable in the string (which
            # should be the LHS of assignment
            set bbb = `echo $aaa | sed -E "s/${vv}//"`

            # then remove the equals sign, then remove any colon
            # separating things
            set ccc = `echo $bbb | sed -E "s/=//" | tr ':' ' ' `

            printf "     + %-30s : %s\n" "'${vv}' dir" "${ccc}"
        else
            set all_other = ( ${all_other} ${vv} )
            #printf "   + %-30s   %s\n" "Could define+use '${vv}'" "in ~/.afnirc" 
        endif
    end

    if ( ${#all_other} ) then
        echo ""
        echo "   ... or define a new AFNI environment var in ~/.afnirc"
        echo "   for a new or existing location on your system, and put"
        echo "   the template file there:"
        echo ""
        foreach other ( ${all_other} ) 
            printf "     + possible env var: %-30s\n" "${other}"
        end
    endif

   echo ""
   echo "+* You might also want to put copies of the following atlases into"
   echo "   the same location, for the 'whereami' functionality to be"
   echo "   available:"
   echo ""

   foreach vol ( ${extra_vols} )
      echo "     + ${refloc}/${vol}"
   end

cat <<EOF

   When that is done, please run this check again to verify all is well:

       tcsh check_for_template.tcsh

EOF


    exit 1
else
    echo ""
    echo "++ Found template  : ${refvol}"
    echo "   ... in location : ${find_list}"
    echo ""
    echo "++ Good to go."

    exit 0
endif
