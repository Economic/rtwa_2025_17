set more off

di "hello"

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop clean_state_mw
program define clean_state_mw 
syntax, mw_csv(string) tipmw_csv(string)

  sysuse state_geocodes, clear
  keep state_abb state_fips state_census
  tempfile state_geocodes
  save `state_geocodes'

  foreach x in mw tipmw {
    if "`x'" == "mw" local mw_var_name stmin
    if "`x'" == "tipmw" local mw_var_name tipmin
  
    import delimited using ``x'_csv', clear
    drop cpivalue
    foreach var of varlist _all {
      if "`var'" != "notes" rename `var' `mw_var_name'`var'
    }
    gen date = date(notes, "YMD")
    gen year = year(date)
    gen month = month(date)
    keep year month `mw_var_name'*
    reshape long `mw_var_name', i(year month) j(state_abb) string
    replace state_abb = "in" if state_abb == "v19"
    replace state_abb = strupper(state_abb)
    drop if state_abb == "US"
    merge m:1 state_abb using `state_geocodes', assert(3) nogenerate
    rename state_fips pwstate
    rename state_census statecensus
    keep year month `mw_var_name' pwstate statecensus
    keep if year >= 2022
    tempfile state_`x'
    save `state_`x''
  }
  
  use `state_mw', clear 
  merge 1:1 year month pwstate statecensus using `state_tipmw', assert(3) nogenerate
  
  label variable stmin "State minimum wage"
  label variable tipmin "State tipped minimum wage"
  label variable pwstate "State FIPS code"
  label variable statecensus "State Census code"
  gen mdate = ym(year,month)
  format %tm mdate
  label variable mdate "Month and Year"
  
  save ${input_clean_dir}state_mins.dta, replace

end

clean_state_mw, `stata_arguments'
