/*
gini-libro.do (user-written ado)

Computes the weighted Gini coefficient for a variable.
Source: Stata-based poverty/inequality toolkit ("libro" collection of
user-written programs), adapted for this project. Not modified except
for comment translation.

Example usage:
  gini cons_pc [w=weight_per] if cons_pc>0
*/

capture program drop gini
program define gini, rclass
  syntax varlist(max=1) [if] [iweight]
  tokenize `varlist'
  quietly {

    preserve

    tempvar each i tmptmp

    * touse = 1 -> observation satisfies if & is not missing
    * touse = 0 -> observation does not satisfy if | is missing
    marksample touse
    keep if `touse' == 1

    local wt : word 2 of `exp'
    if "`wt'"=="" {
      local wt = 1
    }

    summarize `1' [`weight'`exp']
    * mean
    local media=r(mean)
    * reference population
    local obs=r(sum_w)

    sort `1'

    gen `tmptmp' = sum(`wt')
    gen `i' = (2*`tmptmp'-`wt'+1)/2
    gen `each' = `1'*(`obs'-`i'+1)
    summ `each' [`weight'`exp']
    local gini = 1 + (1/`obs') - (2/(`media'*`obs'^2)) * r(sum)

    return scalar gini = `gini'

    restore
  }
  display as text "Gini `1' = " as result %5.4f `gini'
end
