/*
01a3_services.do

Housing-related services component of the consumption aggregate (phone,
electricity, water, internet, cable, rent). Produces household-level
monthly services spending. Called from 01a_prepare_consumption_data.do.
*/

** 1. Section 4, Part "Habitos y Practicas", Questions P09 and P10
*** 1.1 Reference period: last month

tempfile habits
use "$root/data/raw/ECV6R_PERSONAS.dta", clear

local dummy_1="ph09a ph09b ph09c ph10a ph10b"
des `dummy_1'
sum `dummy_1'

MissingValues ph10b 	    /* recodes -1 don't know/no answer */
replace ph10b=. if ph10b==0

CheckAnswers2 ph 10 10

*** 1.2 Total spending on mobile phone

gen double aux_ph10b=ph10b if ph09a==1 & ph10a==1

bysort numhog: egen double spending_mobile=total(aux_ph10b), missing

collapse (mean) spending_mobile, by(numhog)
rename spending_mobile mobile

replace mobile=180 if mobile>=180 & mobile<.

save "`habits'", replace


** 2. Section 1, Part A, P22, P28, P30, P32, P34, P36 to P40
*** Reference period: last month

use "$root/data/raw/ECV6R_VIVIENDA.dta", clear

merge 1:1 numhog using "`habits'"

*** 2.1 Services payments

local dummy_2="vi22* vi28* vi30* vi32* vi34*"
des `dummy_2'
sum `dummy_2'

MissingValues `dummy_2'
ZeroToOne vi22b vi28b vi30b vi32b vi34b		/* cannot be zero when reporting a payment */

sum `dummy_2'

CheckAnswers4 vi22 vi28 vi30 vi32 vi34

HouseMonthly vi22 vi28 vi30 vi32 vi34

ZeroToMissing pay*						/* zeros are not considered in the consumption aggregate */

sum pay*

*** 2.2 Housing payments

local dummy_3="vi36* vi37* vi38* vi39* vi40*"
des `dummy_3'
sum `dummy_3'

MissingValues vi36* vi37* vi38* vi39* vi40*

gen double house_payment=.								
replace house_payment=vi37a if vi37==1 & vi36==1 | vi36==2	
replace house_payment=vi39 if vi36==3	| vi36==4			/* uses what the household would pay in rent (vi39) */
replace house_payment=vi40 if vi36==5 | vi36==6


** 2. Total household services and housing
/*
Impute phone, electricity, internet and cable: if household reports
having the service but no value, impute with the mean (split by
urban/rural), same approach as for durables.
max value for phone+mobile=80
*/
/* Imputation caps based on the observed distribution */

replace payment_vi22=90 if payment_vi22>90 &  payment_vi22!=.
replace payment_vi28=140 if payment_vi28>=140 & payment_vi28!=.
replace payment_vi30=100 if payment_vi30>100 & payment_vi30!=.		/* inconsistency in max value */
replace payment_vi34=110 if payment_vi34>110 & payment_vi34!=.
replace house_payment=1000 if house_payment>1000 & house_payment!=.

rename payment_vi22 water
rename payment_vi28 electricity
rename payment_vi30 phone
rename payment_vi32 internet
rename payment_vi34 cable
rename house_payment rent


** 2.2 Imputation if household reports having a service but not its value
** Note: water and rent sometimes get paid together by households

** electricity
sum electricity if area==1
local urban_elec=`r(mean)'

sum electricity if area==2
local rural_elec=`r(mean)'


replace electricity=`urban_elec' if vi28==1 & electricity==. & area==1
replace electricity=`rural_elec' if vi28==1 & electricity==. & area==2

** phone

egen double aux_phone=rowtotal(phone mobile), miss
replace aux_phone=. if aux_phone==0
sum aux_phone		/* mobile was not asked in LSMS 2005; the 2014 question is phone spending only */


sum  aux_phone if area==1
local urban_phone=`r(mean)'

sum  aux_phone if area==2
local rural_phone=`r(mean)'


replace aux_phone=`urban_phone' if vi30==1 & aux_phone==. & area==1
replace aux_phone=`rural_phone' if vi30==1 & aux_phone==. & area==2

replace phone=aux_phone

** cable
sum  cable if area==1
local urban_cable=`r(mean)'

sum  cable if area==2
local rural_cable=`r(mean)'


replace cable=`urban_cable' if vi33==1 & vi34==1 & cable==. & area==1
replace cable=`rural_cable' if vi33==1 & vi34==1 & cable==. & area==2

** internet
sum  internet if area==1
local urban_internet=`r(mean)'

sum  internet if area==2
local rural_internet=`r(mean)'


replace internet=`urban_internet' if vi32==1 & internet==. & area==1
replace internet=`rural_internet' if vi32==1 & internet==. & area==2

** 3. Total spending on services

egen double services_1=rowtotal(water electricity phone internet cable rent), missing

bysort numhog: egen double services_total=total(services_1), missing

collapse (mean) services_total water electricity phone internet cable mobile rent , by(numhog)
