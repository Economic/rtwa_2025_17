set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop clean_pop_projections
program define clean_pop_projections
syntax, pop_csv(string)

  * population projections
    import delimited using `pop_csv', clear
    label variable growthann "Annual growth rate"
    save "${input_clean_dir}pop_projections_8_2020.dta", replace

end

clean_pop_projections, `stata_arguments'
