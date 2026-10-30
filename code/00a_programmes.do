/*
00a_programmes.do

Shared utility programs used throughout the pipeline (missing value
recodes, unit conversions, imputation helpers, results tabulation).
Called once from 00_master.do before 01_poverty_line.do runs.
*/

*** 1. Recode missing values
***** -1 = don't know / no answer / not provided
capture program drop MissingValues
program define MissingValues
foreach var of local 0 {
recode  `var'* (-1=.)
}
end

capture program drop MissingValuesZeros
program define MissingValuesZeros
foreach var of local 0 {
recode  `var'* (0=.)
}
end

capture program drop ZeroToOne
program define ZeroToOne
foreach var of local 0 {
recode  `var'* (0=1)
}
end

capture program drop ZeroToMissing
program define ZeroToMissing
foreach var of local 0 {
recode  `var'* (0=.)
}
end

*** 2. Extreme values
**** Extreme values are defined as the mean plus two standard deviations
**** Not used to impute variables with different groups

capture program drop ExtremeValues
program define ExtremeValues
foreach var of local 0 {
gen double tempvar=`var'
sum  `var'
local mean_var=`r(mean)'
local sd_var=`r(sd)'
replace `var'=(`mean_var'+(2*`sd_var')) if `var'>(`mean_var'+(2*`sd_var')) & tempvar!=.
drop tempvar
}
end


capture program drop ExtremeValues_mean3sd
program define ExtremeValues_mean3sd
foreach var of local 0 {
gen double tempvar=`var'
sum  `var'
local mean_var=`r(mean)'
local sd_var=`r(sd)'
replace `var'=(`mean_var'+(3*`sd_var')) if `var'>(`mean_var'+(3*`sd_var')) & tempvar!=.
drop tempvar
}
end

*** Used for variables with different groups

capture program drop ImputeMultipleGroups
program define ImputeMultipleGroups
args target groups
bysort `groups': egen double aux_mean_`target'=mean(`target')
bysort `groups': egen double aux_sd_`target'=sd(`target')
gen double aux_impute_`target'=aux_mean_`target'+(2*aux_sd_`target')
replace aux_impute_`target'=. if `target'==.
replace `target'=aux_impute_`target' if `target'>aux_impute_`target'
drop aux_impute_`target'
end

*** Used to impute services

capture program drop ImputeServices
program define ImputeServices
foreach var of local 0 {
egen double aux_mean_`var'=mean(payment_`var')
replace payment_`var'=aux_mean_`var' if `var'a==. & `var'b>0 &  `var'b!=.
replace payment_`var'=aux_mean_`var' if `var'a==0 & `var'b>0 &  `var'b!=. & payment_`var'==.
drop aux_mean_`var'
}
end

*** 3. Converts year to monthly values

capture program drop YeartoMonth
program define YeartoMonth
foreach var of local 0 {
replace `var'=`var'/12
}
end

*** 4. Converts house spending to monthly values (section vivienda/housing)

capture program drop HouseMonthly
program define HouseMonthly
foreach var of local 0 {
gen double payment_`var'=`var'a/`var'b
sum payment_`var'
}
end


*** 5. Converts weekly spending to monthly spending
** Corresponds to 30/7=4.2857143

capture program drop WeeklyMonthly
program define WeeklyMonthly
foreach var of local 0 {
replace `var'=`var'*4.2857143
}
end

*** 6. Converts quarterly spending to monthly spending

capture program drop QuartelyMonthly
program define QuartelyMonthly
foreach var of local 0 {
replace `var'=`var'/3
}
end

*** 7. Converts annual spending to monthly spending

capture program drop AnnualMonthly
program define AnnualMonthly
foreach var of local 0 {
replace `var'=`var'/12
}
end


*** 8. Checks consistency between declared items and reported spending
*** (ensures there is a value reported for each item where the answer is yes)

capture program drop CheckAnswers
program define CheckAnswers
args name star end
forvalues i=`star'(1)`end' {
sum `name'0`i'01 `name'0`i'02 if `name'0`i'01==1
}
end

capture program drop CheckAnswers1
program define CheckAnswers1
args name star end
forvalues i=`star'(1)`end' {
sum `name'`i'01 `name'`i'02 if `name'`i'01==1
}
end

capture program drop CheckAnswers2
program define CheckAnswers2
args name star end
forvalues i=`star'(1)`end' {
sum `name'`i'a `name'`i'b if `name'`i'a==1
}
end

capture program drop CheckAnswers3
program define CheckAnswers3
args name star end
forvalues i=`star'(1)`end' {
sum `name'`i'1 `name'`i'2 if `name'`i'1==1
}
end


capture program drop CheckAnswers4		/* For services */
program define CheckAnswers4
args name star end
foreach var of local 0 {
sum `var' `var'a `var'b if `var'==1
}
end

*** 9. Non-food imputation

capture program drop ImputationNonFood
program define ImputationNonFood
foreach name of local 0 {
args `name'
sum `name'02
replace `name'02=`r(mean)' if `name'01==1 & `name'02==.
}
end


*** 10. Converts to grams and milliliters
/*
To grams
 1 Kilo    =   1000    grams
 1 Ounce   =     28.35 grams
 1 Pound   =    453.6  grams
 1 Arroba  =  11337.87 grams
 1 Quintal =  45351.47 grams

To milliliters
 1 cubic centimeter   =     1 milliliter
 1 liter              =  1000 milliliters
 1 gallon             =  3785.41 milliliters

Frequency codes in dataset
  1 Gram
  2 Ounce
  3 Pound
  4 Kilo
  5 Arroba
  6 Quintal
  7 Cubic centimeters
  8 Milliliter
  9 Liter
 10 Gallon
*/


capture program drop ToGramsMililiters
program define ToGramsMililiters
args name target
gen double `name'=`target'
recode `name' (1 = 1) (2 = 28.35) (3 = 453.6) (4 = 1000) (5 = 11337.87) (6	= 45351.47) (7	= 1) (8	= 1) (9	= 1000) (10	= 3785.41)
end


*** 11. Converts frequency codes to months and days
***    Used in food.do
/*
Frequency codes in dataset
							To months						To days
1 Daily						30								1
2 Weekly					4.2857143						7
3 Biweekly					2							   15
4 Monthly					1							   30
5 Quarterly				   1/3  =.33333333	              1/90 = .01111111
6 Semiannual				   1/6  =.16666667				 1/180 = .00555556
7 Annual					   1/12 =.08333333				 1/360 = .00277778
*/

capture program drop ToMonths
program define ToMonths
args name  target
gen double `name'=`target'
recode `name' (1 = 30) (2 = 4.2857143) (3 = 2) (4 = 1) (5 = .33333333) (6 = .16666667) (7 = .08333333)
end

capture program drop ToDays
program define ToDays
args name  target
gen double `name'=`target'
recode `name' (1 = 30) (2 = 4.2857143) (3 = 2) (4 = 1) (5 = .33333333) (6 = .16666667) (7 = .08333333)
replace `name'=`name'/30
end


*** 12. Poverty results

capture program drop PovertyResults
program define PovertyResults
foreach var of local 0 {
qui tab `var' [w=weight_per], matcell(x)
svmat x
egen double tot = total(x1)
gen double `var'_lsms2014 = 100*x1/tot
drop x1 tot
}
end
