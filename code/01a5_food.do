/*
01a5_food.do

Food (market purchases and self-consumption) component used both for
the consumption aggregate and for the caloric intake calculation.
Called from 01a_prepare_consumption_data.do and from
01a7a_prepare_calories_data.do.
*/

use "$root/data/raw/ECV6R_GASTOS_ALIMENTOS.dta", clear

** Only products also used in LSMS 2005 are kept
** Market purchase items
replace ga07=. if ga00==12 | ga00==15 | ga00==22 | ga00==23 | ga00==33 | ga00==35 | ga00==37 | ga00==44 | ga00==45 | ga00==55 | ga00==59 | ga00==61 | ga00==71 | ga00==78 | ga00==82 | ga00==91 | ga00==98 | ga00==100 | ga00==101 | ga00==103 | ga00==104 | ga00==106 | ga00==109 | ga00==110

replace ga07=. if ga00>111

** Self-consumption items
replace ga11=. if ga00==12 | ga00==15 | ga00==22 | ga00==23 | ga00==33 | ga00==35 | ga00==37 | ga00==44 | ga00==45 | ga00==55 | ga00==59 | ga00==61 | ga00==71 | ga00==78 | ga00==82 | ga00==91 | ga00==98 | ga00==100 | ga00==101 | ga00==103 | ga00==104 | ga00==106 | ga00==109 | ga00==110

replace ga11=. if ga00>111



** 1. Section 10, Part A, Questions P04 to P11
** Only includes goods 1 to 112 (see questionnaire)
*** 1.1 Market purchases

local dummy_1="ga00 gaali ga04 ga05 ga06a ga06bd ga06b ga07"
des `dummy_1'
sum `dummy_1'

MissingValues ga06a ga07

/*
Steps:
		1. Convert quantities to grams and milliliters
		2. Convert quantities in grams to grams per day
		3. Convert spending to monthly values (USD spent per month)
*/
ToGramsMililiters food_GramsMiliter ga06b     			
										/* converts everything to grams
										   requires: new variable name and target variable */

ToDays food_days ga05					
										/* converts everything to days
										   requires: new variable name and target variable */

gen double food_GramsMiliterDay=ga06a*food_GramsMiliter*food_days	
										/* food in grams/milliliters per day */

ToMonths food_months ga05				
										/* converts everything to months
										   requires: new variable name and target variable */

gen double food_SpendingMonthly=ga07*food_months if ga04==1		
										/* food spending in USD per month */


*** 1.2 Self-consumption

local dummy_2="ga08a ga08b ga09 ga10a ga10bd ga10b ga11"
des `dummy_2'
sum `dummy_2'

MissingValues ga10a  ga11

/*
Steps:
		1. Convert quantities to grams and milliliters
		2. Convert quantities in grams to grams per day
		3. Convert spending to monthly values (USD spent per month)
*/

ToGramsMililiters selfconsumption_GramsMiliter ga10b     								
												/* converts everything to grams
												   requires: new variable name and target variable */

ToDays selfconsumption_days ga09	  						
												/* converts everything to days
												   requires: new variable name and target variable */

gen double selfconsumption_GramsMiliterDay=ga10a*selfconsumption_GramsMiliter*selfconsumption_days	
												/* food in grams/milliliters per day */

ToMonths selfconsumption_months ga09								
												/* converts everything to months
												   requires: new variable name and target variable */

gen double selfconsumption_SpendingMonthly=ga11*selfconsumption_months	if ga08a==1			
												/* food spending in USD per month */
