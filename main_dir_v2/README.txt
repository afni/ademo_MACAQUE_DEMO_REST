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

--------------------------------------------------------------------------

SITES PROVIDING DATA, 

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


INPUTS and DATA

+ Raw (=input) data directory tree:

  data_00_basic/
  ├── sub-01/
  │   ├── README.txt
  │   └── ses-01/
  │       ├── anat/
  │       │   └── sub-01_T1w.nii.gz
  │       └── func/
  │           ├── sub-01_ses-01_task-rest_run-01_mion.nii.gz
  │           └── sub-01_ses-01_task-rest_run-02_mion.nii.gz
  ├── sub-02/
  │   ├── README.txt
  │   └── ses-01/
  │       ├── anat/
  │       │   └── sub-02_T1w.nii.gz
  │       └── func/
  │           ├── sub-02_ses-02_task-rest_run-01_mion.nii.gz
  │           └── sub-02_ses-02_task-rest_run-02_mion.nii.gz
  ├── sub-03
  ... etc. ...
  
  where:
    *T1w*.nii.gz       : anatomical (T1w) dataset, whole brain, with skull

    *task-rest*.nii.gz : resting state functional (EPI) datasets,
                          which are raw EPIs

  NB: some datasets underwent a light pre-preprocessing
  here---basically, an extra curation.  In particular, the coordinates
  for some datasets were unreasonably far from having the data loosely
  centered around the coordinate origin.  Additionally, some
  anatomicals were not short type, so we converted them to be (to take
  up less disk space with essentially no loss of information).  For
  details, see the README.txt in each data_00_basic/sub*/ directory.


+ Reference template directory: ./NMT_v2.1_sym/

  This contains macaque standard space data downloaded with
  @Install_NMT, including datasets at 0.5 mm iso voxel size:

    NMT2_*SS.nii.gz     : skullstripped template, in/defining NMT2 
                          space (for more info, see Jung et al., 2020)

    CHARM*_*.nii.gz     : CHARM atlas in the NMT2 space
                          (for more info, see Jung et al., 2020)

    ... and many more datasets and supplementary files

--------------------------------------------------------------------------

SCRIPTS

+ Overview/running

  Processing scripts are all contained in the ./scripts/ directory.

  Each script comes in a pair, such as do_13_aw.tcsh and run_13_aw.tcsh:

    do_*.tcsh     : a script to process one subject

    run_*.tcsh    : a script to loop over one or more subjects, calling
                    the associated do_*.tcsh script

  The processing scripts are made to be run from the scripts/
  directory.  To process the data, users should execute the run_*.tcsh
  scripts, such as with:

    tcsh run_20_ap_vox.tcsh

  The following pairs are included (each to be run):

+ do_13_aw.tcsh, via run_13_aw.tcsh

  Run @animal warper to calculate nonlinear warps from the anatomical
  to a template space (here, NMT); map additional data (e.g., atlases
  and segmentations) between the spaces; also estimate
  skullstripping/brainmasking of the anatomical volume.

  These scripts populate the data_13_aw/ directory. Output data
  include:

    - the warps to- and from- standard space
    - a skull-stripped version of the anatomical
    - a whole brain mask of the anat
    - a copy of the NMT warped to the anat orig space
    - a copy of the D99 atlas warped to the anat orig space
    - surface versions of the atlases and 'driver' scripts to visualize
    - QC images of this processing (alignments, etc.)

               
+ do_20_ap_vox.tcsh, via run_20_ap_vox.tcsh

  Run afni_proc.py to generate a full FMRI processing script for
  *voxelwise* analysis, and carry out the processing.  This command
  uses the output of the *13_aw* scripts.

  A number of reasonable processing parameters have been chosen
  (censoring params, pretty light blurring, etc.), but could certainly
  be tweaked.

+ do_22_ap_roi.tcsh, via run_22_ap_roi.tcsh

  Run afni_proc.py to generate a full FMRI processing script for
  *ROI-based* analysis, and carry out the processing.  This command
  uses the output of the *13_aw* scripts.

  A number of reasonable processing parameters have been chosen
  (censoring params, etc.), but could certainly be tweaked.

+ do_30_pp_roi.tcsh, via run_30_pp_roi.tcsh

  Run some basic post-processing of interest.  Specifically, use the
  data that was processed for ROI-based analysis and calculate
  functional correlation matrices, based on average time series after
  afni_proc.py-processing, using ROIs from the @animal_warper mapping.

  AFNI's 3dNetCorr is used to calculate the matrices, and
  fat_mat2d_plot.py is used to make plots of each (SVG files, so they
  can be zoomed arbitrarily).  We use the CHARM atlas for this
  example.

--------------------------------------------------------------------------

QC OUTPUTS FROM PROCESSING (EXAMPLES)

There are QC_* directories that show the QC images of the
@animal_warper (AW) and afni_proc.py (AP) processing for each subject.
(This demo is already fairly large, and downloading all processed data
is unrealistic.)

   + QC_data_13_aw      : QC images of the volumetric output from AW.  These
                         are just JPGs and PNGs, so use any image viewer to 
                         browse.

   + QC_data_2?_ap*     : QC HTMLs produced by afni_proc.py to summarize
                         and check each block of processing.  These
                         can be viewed in a browser, e.g., using:

                         firefox QC_data_20_ap_vox/sub-0*/*/QC*/index.html

****data_03_postproc   : The correlation matrix output from the 3dNetCorr 
                         and images of these matrices via fat_mat2d_plot.py

============================================================================
============================================================================

Version history
---------------

---------------------------------------------------------------------------
ver  = 2.2; date = Oct 25, 2021

+ Realizing I had made a float-> short mistake in converting sub-3222?
  dset anatomicals (too large of positive values got wrapped to
  negative ones); have fixed now by scaling the anatomicals down by
  ten before converting to short.

---------------------------------------------------------------------------
ver  = 2.1; date = Oct 25, 2021

+ Several align_epi_anat specializations added for different dsets; in part
  because many come from different sites and have very different properties
  (inhomogeneities, noise, distortions, etc.)

---------------------------------------------------------------------------
ver  = 2.0; date = Oct 23, 2021

+ Now using NMT v2.1
+ a wee bit more afni_proc.py output (TSNR images)
+ reformat single proc script into scripts/{do,run}_*tcsh to be easier
  to read (hopefully)
+ simplify and homogenize data_00_basic structure: now each subj has
  exactly 1 ses-* dir

---------------------------------------------------------------------------
ver  = 1.1; date = Aug 3, 2020

+ adjust afni_proc.py command to improve EPI-anat alignment in a
  couple cases

----------------------------------------------------------------------------

ver  = 1.0; date = July 31, 2020

+ Several rounds of analysis tweaks and code updates have occurred
  even in this short gestation period of developing this demo.
+ Converted all dsets to dtype=short.

