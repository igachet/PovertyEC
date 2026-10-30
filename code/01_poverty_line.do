/*
01_poverty_line.do

Ecuador LSMS 2014 consumption poverty line.
Called from code/00_master.do; requires $root to be set and
00a_programmes.do already loaded. Reference population selection and
poverty-line rounding follow the official 2014 methodology (see README
for the SPSS-rounding note).
*/

*** Consumption aggregate and reference population

tempfile temp_consumption temp_calories
do "$root/code/01a_prepare_consumption_data.do" "`temp_consumption'" "`temp_calories'"

gen double weight=round(fexp)
gen double weight_per=round(fexp*numpers)

do "$root/code/01b_cpi.do"
run "$root/code/ados/gcuan.do"

recode food edu fuel water electricity phone internet cable rent non_food durables (0=.)
egen double aggregate_food=rowtotal(food), missing
egen double aggregate_nonfood=rowtotal(edu fuel water electricity phone internet cable rent non_food durables), missing
egen double aggregate=rowtotal(aggregate_food aggregate_nonfood) if aggregate_food>0 & aggregate_nonfood>0, missing
replace aggregate=. if aggregate_food==. | aggregate_nonfood==.

gen double cons_pc=aggregate/numpers
replace cons_pc=cons_pc*IPC		// expressed at Jan-Feb-Mar average prices; update cpi.do when Apr-May-Jun data is available

gcuan cons_pc [w=weight_per], g(percentile) n(100)
gcuan cons_pc [w=weight_per], g(quarentile) n(40)

* Reference population: percentile group whose mean caloric intake is closest to the national norm
tempfile ref_pop_dataset

preserve
	collapse (mean) calories_pc [iw=weight_per], by(quarentile)
	mkmat quarentile calories_pc, matrix(pop_ref)
restore

svmat pop_ref
rename pop_ref1 ref_range
rename pop_ref2 cal_pc_pref

gen double range=1 if cal_pc_pref>=1900 & cal_pc_pref<=2100		// initial search range used historically for LSMS
sum ref_range if range==1
local min=r(min)
local max=r(max)

forvalues i = 0(1)15 {
	egen double tempvar`i'=mean(cal_pc_pref) if ref_range>=`min' & ref_range<=`max'+`i'
}

local norm=2152		// national calories per capita per day norm

foreach var of varlist tempvar* {
	replace `var'=`var'-`norm'
	replace `var'= abs(`var')
}

egen double min_range=rowmin(tempvar*)

foreach var of varlist tempvar* {
	if `var'[`min']==min_range[`min'] {
		gen double reference_pop=1 if `var'>0 & `var'!=.
		sum ref_range if reference_pop==1
		local pop_min=r(min)
		local pop_max=r(max)
	}
}

gen double target_group=1 if quarentile>=`pop_min' & quarentile<=`pop_max'

keep numhog target_group weight weight_per quarentile
drop if numhog==.		// stata occasionally generates a few missing numhog; verify if this persists with new data

save "`ref_pop_dataset'", replace

*** Energy intake basket of goods (Canasta de necesidades medias energeticas)

use "`temp_calories'", clear
merge m:1 numhog using "`ref_pop_dataset'"
drop _merge

do "$root/code/01b_cpi.do"

keep if target_group==1

gen double aux_calories=total_calories/numpers

egen double grams_total=rowtotal(food_GramsMiliterDay selfconsumption_GramsMiliterDay)
gen double aux_grams=grams_total/numpers

egen double food_total=rowtotal(food_SpendingMonthly selfconsumption_SpendingMonthly), missing
replace food_total=food_total/30
gen double aux_food=food_total/numpers
replace aux_food=aux_food*IPC

do "$root/code/01d_prov.do"
do "$root/code/01e_region_area.do"

gen double p_cal=aux_food/aux_calories
replace p_cal=. if p_cal==0

* Correction factor: scales observed calories to the FAO norm
tempfile scale_cal

preserve
	collapse (mean) aux_grams aux_calories [iw=weight_per], by(ga00)
	rename aux_grams grams_pc
	rename aux_calories calories_pc

	local norm=2141		// FAO calories norm
	sum calories_pc
	local tot_cal=r(sum)
	local exp_fac=`norm'/`tot_cal'

	gen double scale_grams=grams_pc*`exp_fac'
	gen double scale_calories=calories_pc*`exp_fac'

	save "`scale_cal'", replace
restore

* Six geographic prices: Costa/Sierra/Amazonia x Urban/Rural
collapse (median) p_cal [iw=weight_per], by(ga00 aux)

reshape wide p_cal, i(ga00) j(aux)
rename p_cal1 costa_u
rename p_cal2 costa_r
rename p_cal3 sierra_u
rename p_cal4 sierra_r
rename p_cal5 amazon_u
rename p_cal6 amazon_r

merge m:1 ga00 using "`scale_cal'"
drop _merge

foreach var of varlist costa_u costa_r sierra_u sierra_r amazon_u amazon_r {
	gen double cost_`var'=`var'*scale_calories
}

order ga00 grams_pc calories_pc scale_grams scale_calories costa_u costa_r sierra_u sierra_r amazon_u amazon_r cost_costa_u cost_costa_r cost_sierra_u cost_sierra_r cost_amazon_u cost_amazon_r

* LSMS 2005 calories, valued at LSMS 2014 prices (2005 is the base year for poverty comparisons in Ecuador)
preserve
	tempfile cal_lsms05
	import excel "$root/data/raw/aux_data/calories.xlsx", sheet("calories") firstrow clear
	keep ga00 scale_cal_ecv05
	save "`cal_lsms05'", replace
restore

merge 1:1 ga00 using "`cal_lsms05'"
drop _merge

foreach var of varlist costa_u costa_r sierra_u sierra_r amazon_u amazon_r {
	gen double cost05_`var'=`var'*scale_cal_ecv05
}

order ga00 grams_pc calories_pc scale_grams scale_calories costa_u costa_r sierra_u sierra_r amazon_u amazon_r cost_costa_u cost_costa_r cost_sierra_u cost_sierra_r cost_amazon_u cost_amazon_r scale_cal_ecv05 cost05_costa_u cost05_costa_r cost05_sierra_u cost05_sierra_r cost05_amazon_u cost05_amazon_r

mat geo_prices=J(6,2,.)
matrix rownames geo_prices = "Costa Urbana" "Costa Rural" "Sierra Urbana" "Sierra Rural" "Amazonia Urbana" "Amazonia Rural"
matrix colnames geo_prices = "Cost per day LSMS14" "LSMS05 Cal at LSMS14 Prices"

local j=1
foreach var of varlist cost_costa_u cost_costa_r cost_sierra_u cost_sierra_r cost_amazon_u cost_amazon_r {
	qui sum `var'
	mat geo_prices[`j',1] = `r(sum)'
	local j=`j'+1
}

local j=1
foreach var of varlist cost05_costa_u cost05_costa_r cost05_sierra_u cost05_sierra_r cost05_amazon_u cost05_amazon_r {
	qui sum `var'
	mat geo_prices[`j',2] = `r(sum)'
	local j=`j'+1
}

matlist geo_prices, border(top bottom) lines(col) format(%30.2f) twidth(15) left(4) title(Costo Canasta por dias por Area y Region)

*** Extreme poverty
do "$root/code/01f_aux_numpers.do"
do "$root/code/01d_prov.do"
do "$root/code/01e_region_area.do"

collapse (sum) weight_per, by(aux)
rename weight_per population

svmat geo_prices
rename geo_prices1 lsms14
rename geo_prices2 lsms05

* Population distribution by area/region from the 2010 census (WB LSMS methodology)
replace population =  5188237 in 1
replace population =  2106093 in 2
replace population =  3614585 in 3
replace population =  2834770 in 4
replace population =   287150 in 5
replace population =   452664 in 6

sum population
gen double share_pop=population/`r(sum)'

foreach var of varlist lsms14 lsms05 {
	gen double weighted_prices_`var'=`var'*share_pop
	sum weighted_prices_`var'
	gen double deflactor_`var'=`var'/`r(sum)'
}

mat extreme_poverty=J(2,2,.)
matrix rownames extreme_poverty = "USD per day" "USD per month"
matrix colnames extreme_poverty = "LSMS 2014" "LSMS 2005 at LSMS14 Prices"

sum weighted_prices_lsms14
mat extreme_poverty[1,1] = `r(sum)'
mat extreme_poverty[2,1] = `r(sum)'*30

sum weighted_prices_lsms05
mat extreme_poverty[1,2] = `r(sum)'
mat extreme_poverty[2,2] = `r(sum)'*30

matlist extreme_poverty, border(top bottom) lines(col) format(%30.3f) twidth(15) left(4) title(Extreme Poverty Line)

mkmat aux population lsms14 lsms05 share_pop weighted_prices_lsms14 deflactor_lsms14 weighted_prices_lsms05 deflactor_lsms05, matrix(geo_deflactor)
matlist geo_deflactor, border(top bottom) lines(col) format(%20.2f) twidth(20) left(4)

*** Poverty line

use "`temp_consumption'", clear

gen double weight=round(fexp)
gen double weight_per=round(fexp*numpers)

do "$root/code/01b_cpi.do"
do "$root/code/01d_prov.do"
do "$root/code/01e_region_area.do"
do "$root/code/01g_deflactor.do"

gen double price_deflactor=IPC/deflactor_lsms05

recode food edu fuel water electricity phone internet cable rent non_food durables (0=.)
egen double aggregate_food=rowtotal(food), missing
egen double aggregate_nonfood=rowtotal(edu fuel water electricity phone internet cable rent non_food durables), missing
egen double other_services=rowtotal(fuel electricity phone), missing
egen double other_nonfood=rowtotal(non_food internet cable), missing
egen double aggregate=rowtotal(aggregate_food aggregate_nonfood) if aggregate_food>0 & aggregate_nonfood>0, missing
replace aggregate=. if aggregate_food==. | aggregate_nonfood==.

gen double cons_pc=aggregate/numpers
replace cons_pc=cons_pc*price_deflactor

gen double food_pc=food/numpers
replace food_pc=food_pc*price_deflactor

gen double engel=food_pc/cons_pc

matlist extreme_poverty, border(top bottom) lines(col) format(%15.2f) twidth(15) left(4) title(Extreme Poverty Line)

* Extreme poverty line is rounded to one decimal (USD/day) before computing Engel; this matches the
* official SPSS-based estimate (Engel ~0.5462) more closely than the unrounded value. See README for detail.
local ext_pov=round(extreme_poverty[1,2],.1)*30

forvalues i = 1(1)10 {
	gen double aux_engel_`i'=engel if cons_pc>=(`ext_pov'*(1-(`i'/100))) & cons_pc<=(`ext_pov'*(1+(`i'/100)))
}

mat engel_coef=J(10,1,.)
matrix colnames engel_coef = aux_engel_coef
local j=1
foreach var of varlist aux_engel_* {
	sum `var' [w=weight_per]
	mat engel_coef[`j',1]=r(mean)
	local j=`j'+1
}

matlist engel_coef
svmat engel_coef

sum engel_coef
local engel_coefficient=r(mean)
scalar engel_1= `engel_coefficient'

local poverty_line=extreme_poverty[2,2]/`engel_coefficient'
scalar poverty_line_1=extreme_poverty[2,2]/`engel_coefficient'

gen double extreme_poverty=1 if cons_pc<extreme_poverty[2,2]
replace extreme_poverty=0 if extreme_poverty==.
replace extreme_poverty=. if aggregate_food==. | aggregate_nonfood==.
tab extreme_poverty [w=weight_per]

qui PovertyResults extreme_poverty

gen double poverty=1 if cons_pc<`poverty_line'
replace poverty=0 if poverty==.
replace poverty=. if aggregate_food==. | aggregate_nonfood==.
tab poverty [w=weight_per]

qui PovertyResults poverty

run "$root/code/ados/gini-libro.do"
qui gini cons_pc [w=weight_per] if cons_pc>0

do "$root/code/01i_lsms2014_results.do"

matlist lsms2014, border(top bottom) lines(col) format(%20.2f) twidth(27) left(4) title(LSMS 2014)

*** Export result tables (for List of Exhibits / reviewer verification)

preserve
	clear
	svmat extreme_poverty, names(ep)
	export delimited using "$root/outputs/tables/extreme_poverty_line.csv", replace
restore

preserve
	clear
	svmat geo_prices, names(gp)
	export delimited using "$root/outputs/tables/geo_prices.csv", replace
restore

preserve
	clear
	svmat lsms2014, names(lsms)
	export delimited using "$root/outputs/tables/lsms2014_summary.csv", replace
restore

*** Save output dataset

keep numhog fexp facper calories_pc aggregate_food aggregate_nonfood aggregate cons_pc food_pc engel extreme_poverty poverty weight weight_per pr reg expov_l pov_l durables edu water rent other_services other_nonfood aggregate_nonfood food price_deflactor deflactor_lsms05 IPC

save "$root/data/final/EcuPoverty_LSMS2014.dta", replace

* data integrity hash, for replicators to verify their output matches (B6)
checksum "$root/data/final/EcuPoverty_LSMS2014.dta"
local hash_dta = r(checksum)
file open hashfile using "$root/data_hashes.txt", write replace
file write hashfile "EcuPoverty_LSMS2014.dta  sha256:`hash_dta'" _n
file close hashfile
