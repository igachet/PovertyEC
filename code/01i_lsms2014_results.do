/*
01i_lsms2014_results.do

Builds the final summary matrix (lsms2014) with extreme poverty,
poverty, Gini and Engel results, and stores the extreme poverty/poverty
line values as variables for export. Called from 01_poverty_line.do.
*/

qui {
mat lsms2014=J(13,1,.)

matrix rownames lsms2014 =  "EXTREME POVERTY" "USD per day" "USD per month"  "(%)" "." "POVERTY" "USD per day" "USD per month" "(%)" "." "GINI" "." "ENGEL"
matrix colnames lsms2014 =  Results

mat lsms2014[2,1] = extreme_poverty[2,2]/30
mat lsms2014[3,1] = extreme_poverty[2,2]
mat lsms2014[4,1] = extreme_poverty_lsms2014[2]

mat lsms2014[7,1] = poverty_line_1/30
mat lsms2014[8,1] = poverty_line_1
mat lsms2014[9,1] = poverty_lsms2014[2]

mat lsms2014[11,1] = r(gini)*100

mat lsms2014[13,1] = engel_1*100

gen expov_l=.
replace expov_l= extreme_poverty[2,2] in 1/1

gen pov_l=.
replace pov_l=poverty_line_1 in 1/1

}
