/*
01a_prepare_consumption_data.do

Builds each component of the consumption aggregate, computes household
caloric intake, and merges everything into the working datasets used by
01_poverty_line.do.

Returns (via tempfile arguments):
  temp_consumption  - household-level consumption aggregate components
  temp_calories      - person/product-level caloric intake data
*/

** 1. Temporary data files
** Used to merge all consumption aggregate components created below

args temp_consumption temp_calories

foreach  x in edu fuel services nofood food durables CaloriesNumpersWeights {
tempfile `x'
}

** 1.2 Build consumption aggregate components
** 1.2.1 Education
do "$root/code/01a1_education.do"
save "`edu'", replace

** 1.2.2 Fuel
do "$root/code/01a2_fuel.do"
save "`fuel'", replace

** 1.2.3 Services
do "$root/code/01a3_services.do"
save "`services'", replace

** 1.2.4 Other non-food
do "$root/code/01a4_non_food.do"
save "`nofood'", replace

** 1.2.5 Food
** Beer is included here (item 111); it was excluded from the 2005-06
** questionnaire, so it is not used in the calorie calculation.

do "$root/code/01a5_food.do"

egen double food_1=rowtotal(food_SpendingMonthly selfconsumption_SpendingMonthly),  missing

bysort numhog: egen double food=total(food_1), missing

collapse (mean) food, by(numhog)

save "`food'", replace

** 1.2.6 Durables

do "$root/code/01a6_durables.do"
save "`durables'", replace

** 1.3 Import calories, household members and weights into the consumption aggregate
** calories.do computes calories per household and already carries
** household members and weights.

do "$root/code/01a7_calories.do"
save `temp_calories', replace

collapse (mean) area (mean) ciudad (mean) periodo (mean) numpers (mean) calories_by_hh (mean) fexp (mean) facper, by(numhog)   
/* computes total calories by household; (mean) is used because the data
   are in long format and total calories were already summed in calories.do */
gen double calories_pc=calories_by_hh/numpers								/* calories per capita */
sum calories_pc
save "`CaloriesNumpersWeights'", replace

** 1.3.1 Merge components

foreach  y in edu fuel services nofood food durables {
merge m:1 numhog using  "``y''"
drop _merge
}

save `temp_consumption', replace
