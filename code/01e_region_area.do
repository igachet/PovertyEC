/*
01e_region_area.do

Combines region (Costa/Sierra/Amazonia) and area (urban/rural) into a
single 6-category indicator (aux) used to compute geographic basket
prices. Called from 01_poverty_line.do.
*/

recode reg (4=1)							/* Galapagos is grouped into Costa */
tab area 


gen aux=.
replace aux=1 if reg==1 & area==1
replace aux=2 if reg==1 & area==2
replace aux=3 if reg==2 & area==1
replace aux=4 if reg==2 & area==2
replace aux=5 if reg==3 & area==1
replace aux=6 if reg==3 & area==2


label define aux 1 "Costa Urbana" 2 "Costa Rural" 3 "Sierra Urbana" 4 "Sierra Rural" 5 "Amazonia Urbana" 6 "Amazonia Rural"
label values aux aux

tab aux, gen(aux)
