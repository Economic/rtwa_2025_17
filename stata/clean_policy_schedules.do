set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop clean_policy_schedules
program define clean_policy_schedules
syntax, scenarios_csv(string)

  * create datasets of proposed policy changes
  import delimited using `scenarios_csv', clear
  label variable new_mw "Proposed minimum wage"
  label variable new_tw "Proposed tipped minimum wage"
  gen mdate = ym(year, month)
  format %tm mdate 
  label variable mdate "Date of proposed min wage change"
  bysort name (mdate): gen step = _n - 1
  save "${input_clean_dir}all_scenarios.dta", replace

end

clean_policy_schedules, `stata_arguments'
