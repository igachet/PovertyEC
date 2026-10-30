/*
01a7_calories.do

Computes total and per-capita caloric intake per household, combining
market-purchase and self-consumption quantities with the caloric content
per product. Called from 01a_prepare_consumption_data.do.
*/

** 1. Prepare data
do "$root/code/01a7a_prepare_calories_data.do"


** 2. Calories per gram per day per capita
** Missing values are treated as zero for this calculation - revisit if
** the underlying food.do logic changes.

gen double calories1=food_GramsMiliterDay*calories
gen double calories2=selfconsumption_GramsMiliterDay*calories

egen double total_calories=rowtotal(calories1 calories2)   

** 2.1 Calories by household

bysort numhog: egen double calories_by_hh=total(total_calories)
