*===============================================================================
* TITLE: Ecuador LSMS 2014 - Consumption Poverty Line - Master Script
*===============================================================================
* Created on : Jul   1, 2014
* Last update: Oct  30, 2026

* Prepared by: Ivan Gachet
* E-mails:    [include email]

* DISCLAIMER:
* This is a personal replication of Ecuador's consumption poverty line
* methodology (LSMS 2014). It is not an official version. It is shared
* for transparency and reproducibility purposes only. Users should review,
* validate, and adapt the code to their own needs; no warranty is made as
* to its fitness for any particular purpose. See README.md for the full
* disclaimer, data availability statement, and run instructions.
*===============================================================================

** 1. Initial setting
global root "D:\Dropbox\povretyEC\"

cap log close
log using "$root/outputs/run_log.log", replace text

set more off
pause off

** 2. Run code
do "$root/code/00a_programmes.do"
do "$root/code/01_poverty_line.do"
log close

