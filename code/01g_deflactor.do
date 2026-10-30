/*
01g_deflactor.do

Merges the geographic deflators (geo_deflactor matrix, built earlier in
01_poverty_line.do) onto the household-level dataset, keyed by the
6-category area/region indicator (aux). Called from 01_poverty_line.do.
*/

matlist geo_deflactor, border(top bottom) lines(col ) format(%20.2f)  twidth(20) left(4)
pause

tempfile geo_def
preserve

** 1. Import geographic prices into a dataset

svmat geo_deflactor 

keep geo_deflactor1 geo_deflactor9

rename geo_deflactor1 aux 
rename geo_deflactor9  deflactor_lsms05
drop if aux==.

save "`geo_def'", replace
restore 

merge m:1 aux using "`geo_def'"
drop _merge
