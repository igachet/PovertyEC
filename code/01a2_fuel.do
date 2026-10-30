/*
01a2_fuel.do

Fuel component of the consumption aggregate (ECV 2013-2014, Section 10,
Part A). Produces household-level monthly fuel spending.
Called from 01a_prepare_consumption_data.do.
*/

use "$root/data/raw/ECV6R_OTROS_GASTOS.dta", clear

** 1. Section 10, Part A (B Monthly spending), Questions P01 to P06
*** Reference period: last month

local dummy_1= "gb0101 gb0102 gb0201 gb0202 gb0301 gb0302 gb0401 gb0402 gb0501 gb0502 gb0601 gb0602"

des `dummy_1'
sum `dummy_1'

MissingValues gb0102 gb0202 gb0302 gb0402 gb0502 gb0602 	    
										/* recodes -1 don't know/no answer */

forvalues i=1(1)6 {
CheckAnswers3 gb0 `i'0 `i'0
}


sum gb0102 gb0202 gb0302 gb0402 gb0502 gb0602

/* Imputation: based on the distribution, there are no significant jumps
   that justify imputing with mean+2/3 SD, so a fixed cap is used instead */

replace gb0102=12.15 if gb0102>12.15 & gb0102!=.	
replace gb0202=5.26  if gb0202>5.26 & gb0202!=.
replace gb0302=34.83  if gb0302>34.83 & gb0302!=.
replace gb0402=6   if gb0402>6 & gb0402!=.
replace gb0502=16.13  if gb0502>16.13 & gb0502!=.
replace gb0602=26.83 if gb0602>26.83 & gb0602!=.

** 2. Total spending on fuel
** gb0502 is excluded because it was not considered in the previous LSMS round

egen double fuel_1=rowtotal(gb0102 gb0202 gb0302 gb0402 gb0602), missing
bysort numhog: egen double spending_fuel=total(fuel_1), missing

collapse (mean) spending_fuel, by(numhog)
rename spending_fuel fuel

sum fuel
