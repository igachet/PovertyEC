/*
01a1_education.do

Education component of the consumption aggregate (ECV 2013-2014,
Section 5). Produces household-level monthly education spending.
Called from 01a_prepare_consumption_data.do.
*/

use "$root/data/raw/ECV6R_PERSONAS.dta", clear

** 1. Section 5, Part A, Questions P04 to P11
*** 1.1 Reference period: last 12 months
local dummy_1= "pe04a pe04b pe05a pe05b pe06a pe06b pe07a pe07b pe08a pe08b"

des `dummy_1'
sum `dummy_1'

MissingValues `dummy_1'						/* recodes -1 don't know/no answer */
sum `dummy_1'
CheckAnswers2 pe0 4 8							/* checks consistency between declaring a spend and the reported amount */

YeartoMonth pe04b pe05b pe06b pe07b pe08b    	/* converts yearly to monthly values */
sum pe04b pe05b pe06b pe07b pe08b

*** 1.2 Reference period: last month
local dummy_2=" pe09a pe09b pe10a pe10b pe11a pe11b"
des `dummy_2'
sum `dummy_2'

MissingValues pe09b pe10b pe11b	    /* recodes -1 don't know/no answer */
CheckAnswers2 pe0 9 9
CheckAnswers2 pe 10 11

*** 1.3 Total education aggregate, part 1

egen double edu_1=rowtotal(pe04b pe05b pe06b pe07b pe08b pe09b pe10b pe11b),  missing

** 2. Section 5, Part B, Questions P38 to P45 and P59
*** 2.1 Reference period: last 12 months

local dummy_3="pe38a pe38b pe39a pe39b pe40a pe40b pe41a pe41b"

des `dummy_3'
sum `dummy_3'
MissingValues pe38b pe39b pe40b pe41b 	    /* recodes -1 don't know/no answer */
CheckAnswers2 pe 38 41

YeartoMonth pe38b pe39b pe40b pe41b   	 /* converts yearly to monthly values */
sum pe38b pe39b pe40b pe41b

*** 2.2 Reference period: last month

local dummy_4="pe42a pe42b pe43a pe43b pe44a pe44b pe45a pe45b"

des `dummy_4'
sum `dummy_4'
MissingValues pe42b pe43b pe44b pe45b 	    /* recodes -1 don't know/no answer */

CheckAnswers2 pe 42 45

*** 2.3 Reference period: last 12 months

local dummy_5="pe59a pe59b"

des `dummy_5'
sum `dummy_5'
MissingValues pe59b	    /* recodes -1 don't know/no answer */

YeartoMonth pe59b    /* converts yearly to monthly values */
sum pe59b

*** 2.3 Total education aggregate, part 2

egen double edu_2=rowtotal(pe38b pe39b pe40b pe41b pe42b pe43b pe44b pe45b pe59b),  missing

** 3. Total spending on education

egen double edu_3=rowtotal(edu_1 edu_2),  missing
bysort numhog: egen double spending_edu=total(edu_3)


** 3.1 Aggregate data to household level

collapse (mean) spending_edu, by(numhog)
rename spending_edu edu

MissingValuesZeros edu

replace edu=2000 if edu>=2000 & edu!=.		/* based on the distribution, there are no significant
											   jumps that justify imputing with mean+2/3 SD */
sum edu
