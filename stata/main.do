set more off
clear all
capture program drop _all 
*adopath ++ "."

* raw model inputs
global input_raw_dir inputs_raw/
* cleaned model inputs
global input_clean_dir inputs_clean/
* model outputs
global output_dir outputs/


* clean up min wage data 
*do clean_state_mw.do

*do clean_misc_projections.do   

*do create_policy_schedule.do 

*do clean_cps.do 

*do run_models.do

*do analyze_results_fake.do

sysuse auto, clear 
keep if mpg < 20
save hello.dta