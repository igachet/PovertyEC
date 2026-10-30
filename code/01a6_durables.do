/*
01a6_durables.do

Durable goods component of the consumption aggregate: converts
reported durable goods values into an imputed monthly use-value
(principal and secondary goods). Called from
01a_prepare_consumption_data.do.
*/

use "$root/data/raw/ECV6R_EQUIPAMIENTO.dta", clear

drop if eq00==5 | eq00==12 | eq00==14 | eq00==21 | eq00==23 | eq00==27 | eq00==35 | eq00==36 | eq00==37		
/* drops goods not included in the aggregate */
tab eq00, nol

** 1. Section 10, Part D, Questions P01 to P04
** Only includes goods 1 to 4, 6 to 11, 13, 15 to 20, 22, 24 to 26, 28 to 34 (see questionnaire)
** Reference period: years

** 1.1 Prepare data

local dummy_1="eq00 eqbien eq01 eq02 eq03 eq04"
des `dummy_1'
sum `dummy_1'

MissingValues eq01 eq02 eq03 eq04								/* replace missing values */

sum `dummy_1'



** 1.2 Impute goods values (eq04)
** If eq04 is greater than the mean plus two standard deviations, we replace
** eq04 with that value, computed separately for each good.

bysort eq00: egen double aux_mean_eq04=mean(eq04)
replace aux_mean_eq04=. if eq04==.
bysort eq00: egen double aux_sd_eq04=sd(eq04)
replace aux_sd_eq04=. if eq04==.

replace eq04=aux_mean_eq04+(2*aux_sd_eq04) if eq04>(aux_mean_eq04+(2*aux_sd_eq04)) & eq04!=.

drop aux*

** 1.3 Impute number of goods (eq02)
** Values 3 and 9 are treated as data entry errors for eq02 - it would be
** unusual for a household to report more than seven similar goods.

sum eq02 if eq02==8  | eq02==9
recode eq02 (8 = 3) (9=3)

** Values above 9 for eq02 are also treated as data entry errors

sum eq02 if eq02>9
replace eq02=trunc(eq02/10) if eq02>9

** If a household reports having a good (eq01) but not its quantity, assume 1

replace eq02=1 if eq01==1 & eq02==.


** 1.3 Impute age of good (eq03)
** If a household reports having a durable good but says it has had it for
** zero years, set this to 1 year.

sum eq03 if eq03==0
recode eq03 (0 = 1)

replace eq03=. if eq03>88								/* values like 99, 88 etc. are data entry issues;
															also no good can be older than ~90 years */

bysort eq00: egen double aux_mean_eq03=mean(eq03)

replace  eq03=aux_mean_eq03 if eq02>=1 & eq03==. & eq02!=.


** 1.4 Impute durable good value
** If a household reports having a durable good but not its value, impute
** using the national average value for that specific good.

sum eq01 if eq01==1 & eq04==.
sum eq01 if eq01==1 & eq04==0

bysort eq00: egen double aux_mean_eq04=mean(eq04)
replace eq04=aux_mean_eq04 if eq01==1 & eq04==.
replace eq04=aux_mean_eq04 if eq01==1 & eq04==0

drop aux_mean_eq04

** 1.4 Impute number of durable goods
** If a household reports having a durable good but declares zero on eq02,
** replace with one (a household must have at least one good).

sum eq02 if eq01==1 & eq02==0
replace eq02=1 if eq01==1 & eq02==0


** 2. Durables use-value (see methodology document for details)
** 2.1 Principal goods
** 2.1.1 Expected good lifetime

bysort eq00: egen double mean_age=mean(eq03)
replace mean_age=. if  eq03==.

gen double VT=2*mean_age

*** 2.1.2 Remaining useful life

gen double VQ=VT-eq03

sum VQ if VQ<0

sum VQ
sum VQ if VQ>1
sum VQ if VQ<=1

*** 2.1.3 Annual use-value

gen double VUA=eq04/VQ if VQ>1
replace VUA=eq04/2 if VQ<=1    		

*** 2.1.4 Monthly use-value

gen double VUM=VUA/12
sum VUM

gen double aux_VUM=(1/12)*(eq04/((2*mean_age)-eq03))

*** 2.2 Secondary goods
*** 2.2.1 Values

bysort eq00: egen double V=mean(eq04)
replace V=. if eq04==.

*** 2.2.2 Age of secondary goods

gen double age_seconday=mean_age-1

*** 2.2.3 Secondary goods monthly use-value

gen double sec_use_value=(eq02-1)*(V/((mean_age+1)*12))

** 3. Total spending on durables

egen double durables_1=rowtotal(sec_use_value VUM), missing
bysort numhog: egen double durables=total(durables_1), missing


collapse (mean) durables, by(numhog)

replace durables=1570 if durables>1570 & durables!=.		/* based on the distribution, there are no
															   significant jumps that justify imputing with mean+2/3 SD */
