/*
01f_aux_numpers.do

Rebuilds household member counts, city/area identifiers and survey
weights from the source data. Used to restore these variables after
earlier merges/collapses dropped them from the working dataset.
Called from 01_poverty_line.do (extreme poverty / basket pricing step).
*/

** 1. Household members
** Keeps city and area here so region_area.do can be run right after

tempfile deletenumpers 
use "$root/data/raw/ECV6R_PERSONAS.dta", clear
bysort numhog: gen double numpers=_N
keep numhog numpers ciudad area 
collapse (mean) numpers (mean) ciudad (mean) area, by(numhog)
save "`deletenumpers'", replace


** 2. Weights

tempfile fexp 
use "$root/data/raw/weights.dta", clear
keep numhog fexp facper  

merge 1:1 numhog using "`deletenumpers'"
drop _merge

gen double weight=round(fexp) 
gen double weight_per=round(fexp*numpers)
