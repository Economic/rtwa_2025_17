set more off

global input_clean_dir inputs_clean/
global output_dir outputs/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop run_mwsim
program define run_mwsim
syntax, ///
  microdata_file(string) ///
  data_stub(string) ///
  policy_name(string) ///
  policy_schedule_file(string) ///
  cpi_file(string) /// 
  pop_file(string) ///
  state_mw_file(string) ///
  [local_mw_file(string)]
  
  use `policy_schedule_file' if name == "`policy_name'", clear
  sum step
  local steps = r(max)
  drop name
  tempfile policy_schedule_input
  save `policy_schedule_input'
  
  use `policy_schedule_input', clear
  merge 1:m mdate using `state_mw_file', keep(3) nogenerate
  drop mdate month year
  reshape wide new_mw new_tw stmin tipmin, i(pwstate) j(step)
  drop new_mw0 new_tw0
  forvalues i = 1/`steps' {
    rename new_mw`i' prop_mw`i'
    rename new_tw`i' prop_tw`i'
  }
  tempfile active_state_mw
  save `active_state_mw'

  if "`local_mw_file'" != "" {
    use `policy_schedule_input', clear
    merge 1:m mdate using `local_mw_file', keep(3) nogenerate
    drop month year new_mw new_tw mdate
    reshape wide local_mw local_tw, i(pwstate pwpuma) j(step)
    tempfile active_local_mw
    save `active_local_mw'
  }
  
  use `microdata_file', clear 
  gen nom_wage_growth0 = 0.05

  * merge counterfactual state minimum wages
  merge m:1 pwstate using `active_state_mw', assert(3) nogenerate

  if "`local_mw_file'" != "" {
    * replace counterfactual state with local minimum wages, if applicable
    merge m:1 pwstate pwpuma using `active_local_mw', assert(1 3)
    drop _merge 
    forvalues a = 1/`steps' {
      replace stmin`a' = local_mw`a' if local_mw`a' > stmin`a' & local_mw`a' != .
      replace tipmin`a' = local_tw`a' if local_tw`a' > tipmin`a' & local_tw`a' != .
    }
    drop local_mw* local_tw*
  }

  tempfile microdata_input
  save `microdata_input'

  local rwg_value = 0.005
  
  mwsim run, microdata(`microdata_input') policy(`policy_schedule_input') steps(`steps') ///
    cpi(`cpi_file') population(`pop_file') real_wage_growth(`rwg_value')

  compress
  save ${output_dir}model_run_microdata_`data_stub'_`policy_name'.dta, replace 

end

run_mwsim, `stata_arguments'


