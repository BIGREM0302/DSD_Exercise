Changes
.synopsys_dc.setup
* search_path, target_library, link_library, symbol_library, synthetic_library

GSIM_DC.sdc:
* input_delay:  from   1 to [$cycle*0.5]
* output_delay: from 0.5 to [$cycle*0.5]
* load:         from   1 to 0.05
* Remove wire load model

license:
* Tool licenses are packed at /share1/cad/cell-based.cshrc

03_run:
* VCS Gate Simulation command
