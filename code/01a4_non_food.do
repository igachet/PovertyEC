/*
01a4_non_food.do

Other non-food spending component of the consumption aggregate
(ECV 2013-2014, Section 10, Part A, weekly/monthly/quarterly/annual
reference periods). Called from 01a_prepare_consumption_data.do.
*/

use "$root/data/raw/ECV6R_OTROS_GASTOS.dta", clear

** 1. Section 10, Part A (A Weekly spending), Questions P01 to P05
*** Reference period: weeks
local dummy_1= "ga0101	ga0102	ga0201	ga0202	ga0301	ga0302	ga0401	ga0402	ga0501	ga0502	ga0601	ga0602	ga0701	ga0702	ga0801	ga0802"

des `dummy_1'
sum `dummy_1'

qui MissingValues `dummy_1'								/* recode missing values */

CheckAnswers ga 1 8

WeeklyMonthly ga0102 ga0202 ga0302 ga0402 ga0502   		
/* converts weekly to monthly spending; only includes items common with LSMS 2005 */

egen double nonfood_1=rowtotal(ga0102 ga0202 ga0302 ga0402 ga0502), missing


** 2. Section 10, Part A (B Monthly spending), Questions P07 to P35
*** Reference period: last month

local dummy_2 = "gb0701	gb0702	gb0801	gb0802	gb0901	gb0902	gb1001	gb1002	gb1101	gb1102	gb1201	gb1202	gb1301	gb1302	gb1401	gb1402	gb1501	gb1502	gb1601	gb1602	gb1701	gb1702	gb1801	gb1802	gb1901	gb1902	gb2001	gb2002	gb2101	gb2102	gb2201	gb2202	gb2301	gb2302	gb2401	gb2402	gb2501	gb2502	gb2601	gb2602	gb2701	gb2702	gb2801	gb2802	gb2901	gb2902	gb3001	gb3002	gb3101	gb3102	gb3201	gb3202	gb3301	gb3302	gb3401	gb3402 gb3501	gb3502"

des `dummy_2'
sum `dummy_2'

MissingValues `dummy_2'

CheckAnswers gb 7 9
CheckAnswers1 gb 10 34

egen double nonfood_2=rowtotal(gb0702 gb0802 gb0902	gb1002 gb1102 gb1202 gb1302	gb1402 gb1502 gb1602 gb1702	gb1802 gb1902 gb2002 gb2102 gb2202 gb2302 gb2402 gb2502 gb2602 gb2702 gb2802 gb2902 gb3002 gb3102 gb3202 gb3302 gb3402 gb3502), missing


** 3. Section 10, Part A (C Quarterly spending), Questions P01 to P08
*** Reference period: last quarter

local dummy_3 = "gc0101	gc0102 gc0201 gc0202 gc0301 gc0302 gc0401 gc0402 gc0501 gc0502 gc0601 gc0602 gc0701 gc0702 gc0801 gc0802"

des `dummy_3'
sum `dummy_3'

MissingValues `dummy_3'	

CheckAnswers gc 1 8

QuartelyMonthly gc0102 gc0202 gc0302 gc0402 gc0502 gc0602 gc0702 gc0802	
											/* converts quarterly to monthly spending */

egen double nonfood_3=rowtotal(gc0102 gc0202 gc0302 gc0402 gc0502 gc0602 gc0702 gc0802), missing


** 4. Section 10, Part A (D Annual spending), Questions P04, P05, P10, P11, P16 to P18, P20 to P23, P25, P26, P28 to P30
*** Reference period: last year

local dummy_4="gd0401 gd0402 gd0501 gd0502 gd1001 gd1002 gd1101 gd1102 gd1601 gd1602 gd1701 gd1702 gd1801 gd1802 gd2001 gd2002 gd2101 gd2102 gd2201 gd2202 gd2301 gd2302 gd2501 gd2502 gd2601 gd2602 gd2801 gd2802 gd2901 gd2902 gd3001 gd3002"

des `dummy_4'
sum `dummy_4'

MissingValues `dummy_4'	

CheckAnswers gd 4 5
CheckAnswers1 gd 10 11
CheckAnswers1 gd 16 18
CheckAnswers1 gd 20 23
CheckAnswers1 gd 25 26
CheckAnswers1 gd 28 30

AnnualMonthly  gd0302 gd0402 gd1002 gd1102 gd1502 gd1602 gd1702 gd1802 gd2002 gd2102 gd2202 gd2302 gd2502 gd2602 gd2802 gd2902  gd3002		
/* same approach as LSMS 2005 */

egen double nonfood_4=rowtotal( gd0302 gd0402 gd1002 gd1102 gd1502 gd1602 gd1702 gd1802 gd2002 gd2102 gd2202 gd2302 gd2502 gd2602 gd2802 gd2902  gd3002), missing


** 3. Total spending on non-food items

egen double non_food=rowtotal(nonfood_1 nonfood_2 nonfood_3 nonfood_4), missing

replace non_food=2750 if non_food>2750 & non_food!=.    		/* based on the distribution, there are no
															   significant jumps that justify imputing with mean+2/3 SD */

sum non_food

keep numhog  non_food
