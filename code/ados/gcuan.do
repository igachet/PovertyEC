/*
gcuan.do (user-written ado)

Generates quantile groups (n-tiles) of a variable using survey weights.
Source: Stata-based poverty/inequality toolkit ("libro" collection of
user-written programs), adapted for this project. Not modified except
for comment translation.

Note: unlike other preserve/restore blocks, this program cannot use
preserve-keep-restore because it needs to add variables to the dataset.
*/

capture program drop gcuan
program define gcuan
  syntax varlist(max=1) [if] [iweight], Ncuantiles(integer) Generate(namelist)

  quietly {

    * touse = 1 -> observation satisfies if & is not missing
    * touse = 0 -> observation does not satisfy if | is missing
    marksample touse

    local wt : word 2 of `exp'
    if "`wt'"=="" {
      local wt = 1
    }

    * temporary variables
    tempvar myvar shrpop popwt

    * copy of `varlist'
    gen `myvar' = `varlist'
    replace `myvar' = . if `touse' != 1

    * sort by `varlist'
    sort `myvar', stable

    gen `popwt' = `wt'
    replace `popwt' = 0 if `touse' != 1

    * cumulative population share
    gen double `shrpop' = sum(`popwt')
    replace `shrpop' = `shrpop'/`shrpop'[_N]

    * share of the sample in each quantile (e.g. 20% if ncuantiles=5)
    local shrcuantil = 1/`ncuantiles'

    * name of the variable to generate with the quantile number for each observation
    local cuantil = "`generate'"

    * identify quantiles of `varlist'
    gen `cuantil' = .
    forvalues i = 1(1)`ncuantiles' {
      replace `cuantil' = `i' if `shrpop' > (`i'-1)*`shrcuantil' ///
        & `shrpop' <= `i'*`shrcuantil' & `myvar' !=.
    }

  }

  * show quantile description
  tabulate `cuantil' [`weight'`exp'], summ(`varlist')

end

exit
