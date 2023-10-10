# mg-segmentation
Adrian et al Nat Comms 2023 - Fiji scripts for microglia segmentation

This simple repro contains the ImageJ/Fiji macros for the following publication:
Adrian, M., Weber, M., Tsai, MC. et al. Polarized microtubule remodeling transforms the morphology of reactive microglia and drives cytokine release. Nat Commun 14, 6322 (2023). https://doi.org/10.1038/s41467-023-41891-6
https://www.nature.com/articles/s41467-023-41891-6

## Instructions:
Download macros as ijm files, drag into Fiji status bar, adjust parameters and run.
Please pay attention to comments in ijm file about input file requirements and folder structure.

MG_segmentation_primarycells.ijm is developed for primary microglia cultured on multiwell plates and stained with CellMask HCS FarRed (ThermoFisher) or equivalent.

MG_segmentation_tissue.ijm is developed for Iba-1 stained brain slices as decribed in the manuscript above. Other stainings may or may not perform equally well.

Parameters for thresholding will need to be optimized empirically for each dataset.

## Requirements

Tested on ImageJ version 1.53t

Requires MorpholibJ (IJPB-plugins http://sites.imagej.net/IJPB-plugins/) and SCF-MBI (SCF MPI CBG	http://sites.imagej.net/SCF-MPI-CBG/) plugins to be installed before running these macros.

