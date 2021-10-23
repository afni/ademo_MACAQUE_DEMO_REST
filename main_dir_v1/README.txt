AFNI's Macaque demo for resting state FMRI

auth = PA Taylor, DR Glen

Thanks to Adam Messinger, Ben Jung and Jakob Seidlitz for both the
accompanying macaque data set and many processing suggestions/advice.
Additionally, thanks to Rick Reynolds for afni_proc.py setup and
processing advice.

For more information on these macaque processing datasets and tools,
see Jung et al., 2020.

For more information about animal data processing on the AFNI website,
see:
https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/nonhuman/main_toc.html

And please feel free to ask questions on the AFNI Message Board!

(See version history below.)

--------------------------------------------------------------------------

DATA

The data comes from multiple centers, and has all been shared as part
of PRIME-DE.  Contributing people+sites for this specific dataset are
(subject IDs are those of the originally distributed data, as there
were no duplications):
+ sub-01, sub-02, sub-03 : Messinger (NIMH, NIH, USA) 
+ sub-032222, sub-032223 : Klink and Roelfsema (Netherlands Institute
                           for Neuroscience, Netherlands)
+ sub-032309             : from Procyk, Wilson and Amiez (Stem Cell and 
                           Brain Research Institute, France)
Thanks to all of them for collecting+providing this data publicly.

We use the original data from a single session in each case (2 EPIs
and 1 T1w anatomical).  All datasets have been converted to "short"
dtype, in order to keep file sizes (relatively) small.  This
introduces a tiny roundoff error, but since the scale of values in all
cases typically of order 1000, this should be a negligible
consideration.

In some cases, the coordinates had to be reset for one or more
datasets, likely due to some step in converting DICOMs or other
preparation for uploading.  As a note for those collecting and
curating data, coordinates and grid setups matter: (x, y, z) = (0, 0,
0) should be near the center of the brain; the EPIs and anatomicals
from a single session should overlap well.

Some datasets here were acquired from anaesthetized macaques, some
were awake.  Some macaques had MION contrast present.  Some macaques
moved a lot during scanning.  Some data are fairly distorted, have
large signal base variation across scans, have dropout due to objects
in the scanner, etc. In some cases the FOV does not contain the entire
brain.  Therefore, there are a wide variety of features to examine and
look for in the QC stages.  There is a README.txt in the
data_00_basic/ directory for each subject that describes a bit more
about each, but more information is also present on the PRIME-DE
website.

--------------------------------------------------------------------------

SCRIPTS

Well, everything has been compacted into one script in the scripts/
directory.  It is aptly named "do_all.tcsh".

It contains the few major processing commands for each subject, which are:

    @animal_warper     : Nonlinearly align data to template, map ROIs from
                         standard to subject space, make surfaces of
                         those ROIs (and scripts to view them
                         directly), perform skullstripping, make QC
                         images of the processing (alignment, skullstripping,
                         and ROI mapping)

    afni_proc.py       : Carry out full single subject processing, from 
                         motion correction through regression.  This uses
                         warp information from @animal_warper.  QC information
                         is made automatically.

                         There are two afni_proc.py runs: one without
                         smoothing, for subsequent ROI-based analyses,
                         and the other with smoothing, for voxelwise
                         analyses.

    3dNetCorr + fat_mat2d_plot.py : 
                         Use the provided atlases and calculate
                         correlation matrices for each subject (using
                         the afni_proc.py output that did *not*
                         include smoothing).  The latter program makes
                         images of the matrices

As noted in the comments of the do_all.tcsh script, you can also
"jump" to a given processing stage by providing a command line keyword
to the script.  However, note that each afni_proc.py command depends
on the @animal_warper stage having completed successfully, and the
correlation matrix calculations depend on ROI-based afni_proc.py
command having completed.

--------------------------------------------------------------------------

QC OUTPUTS FROM PROCESSING

There are QC_* directories that show the QC images of the
@animal_warper (AW) and afni_proc.py (AP) processing for each subject.
(This demo is already fairly large, and downloading all processed data
is unrealistic.)

    QC_data_01_aw      : QC images of the volumetric output from AW.  These
                         are just JPGs and PNGs, so use any image viewer to 
                         browse.

    QC_data_02_ap*     : QC HTMLs produced by afni_proc.py to summarize
                         and check each block of processing.  These
                         can be viewed in a browser, e.g., using:

                         firefox QC_data_02_ap_vox/sub-0*/*/QC*/index.html

    data_03_postproc   : The correlation matrix output from the 3dNetCorr 
                         and images of these matrices via fat_mat2d_plot.py

============================================================================
============================================================================

Version history
---------------

ver  = 1.1; date = Aug 3, 2020

+ adjust afni_proc.py command to improve EPI-anat alignment in a
  couple cases

----------------------------------------------------------------------------

ver  = 1.0; date = July 31, 2020

+ Several rounds of analysis tweaks and code updates have occurred
  even in this short gestation period of developing this demo.
+ Converted all dsets to dtype=short.

