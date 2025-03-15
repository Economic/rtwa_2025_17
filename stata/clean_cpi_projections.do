set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop clean_cpi_projections
program define clean_cpi_projections
syntax, cpi_csv(string)

  * CPI projections
  import delimited using `cpi_csv', clear 
  gen quarter = substr(date, -1, 1)
  destring quarter, replace
  gen year = substr(date, 1, 4)
  destring year, replace 
  gen quarterdate = yq(year, quarter)
  gen mdate = mofd(dofq(quarterdate))
  format %tm mdate
  tsset mdate 
  tsfill
  rename cpi_u old_cpi_u
  egen cpi_u = max(old_cpi_u), by(quarterdate)
  keep mdate quarter cpi_u
  save "${input_clean_dir}cpi_projections_2_2023.dta", replace

end

clean_cpi_projections, `stata_arguments'
