set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

* create datasets of proposed policy changes
import delimited using "${input_raw_dir}all_scenarios.csv", clear
label variable new_mw "Proposed minimum wage"
label variable new_tw "Proposed tipped minimum wage"
gen mdate = ym(year, month)
format %tm mdate 
label variable mdate "Date of proposed min wage change"
bysort name (mdate): gen step = _n - 1
save "${input_clean_dir}all_scenarios.dta", replace




levelsof name, local(scenarios)
foreach x in `scenarios' {
    preserve

    * create policy schedule data
    keep if name == "`x'"
    drop name

    save "${input_clean_dir}modelinputs_`x'.dta", replace

    * create counterfactual & policy min wages 
    local steps = _N-1
    merge 1:m mdate using "${input_clean_dir}state_mins.dta", keep(3) nogenerate
    drop mdate month year
    reshape wide new_mw new_tw stmin tipmin, i(pwstate) j(step)
    drop new_mw0 new_tw0
    label variable stmin0 "State minimum wage in data period"
    label variable tipmin0 "State tipped minimum wage in data period"
    forvalues i = 1/`steps' {
        label variable stmin`i' "State minimum wage at Step `i'"
        label variable tipmin`i' "State tipped minimum wage at Step `i'"

        rename new_mw`i' prop_mw`i'
        rename new_tw`i' prop_tw`i'
    }
    save "${input_clean_dir}active_state_mins_`x'.dta", replace

    restore
} 
