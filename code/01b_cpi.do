/*
01b_cpi.do

Imports the consumer price index (IPC) and builds a deflator that
rebases spending to average prices for Apr-May-Jun, the reference
period used across all LSMS rounds in Ecuador.
Called from 01_poverty_line.do.

TODO: update the cellrange/period once Apr-May-Jun data become available.
*/

tempfile cpi
preserve

** 1.2 Import consumer price index

import excel "$root/data/raw/aux_data/Datos_INEC.xlsx", sheet("Inflacion") cellrange(B11:C143) firstrow clear
tsset Mes
keep if tin(01nov2013,01oct2014)
drop if IPC==.

gen double periodo=_n 		

sum IPC if tin(01apr2014,01jun2014)
local ref_ipc=r(sum)/3
replace IPC=`ref_ipc'/IPC

save "`cpi'", replace
restore 

merge m:1 periodo using "`cpi'"
drop _merge
