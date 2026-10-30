/*
01a7a_prepare_calories_data.do

Prepares the inputs needed to compute caloric intake:
- household member counts
- caloric content per product (from aux data/calories.xlsx)
- survey weights
Merges these onto the food consumption data (01a5_food.do).
Called from 01a7_calories.do.
*/

** 1. Prepare data
** 1.1 Household members

tempfile numpers
use "$root/data/raw/ECV6R_PERSONAS.dta", clear
bysort numhog: gen double numpers=_N
keep numhog numpers
collapse (mean) numpers, by(numhog)
save "`numpers'", replace

** 1.2 Import calories by product
tempfile calories
import excel "$root/data/raw/aux_data/calories.xlsx", sheet("calories") firstrow clear
save "`calories'", replace

** 1.3 Import weights

tempfile fexp
use "$root/data/raw/weights.dta", clear
save "`fexp'", replace

** 1.4 Merge data sets

do "$root/code/01a5_food.do"

merge m:1 numhog using "`numpers'"
drop _merge

merge m:1 ga00 using "`calories'"
drop _merge

merge m:1 numhog using "`fexp'"
gen double pondera=round(fexp)
gen double pondera1=round(facper)
drop _merge
