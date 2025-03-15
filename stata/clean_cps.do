set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop clean_cps_base
program define clean_cps_base
  
  * clean CPS data
  load_epiextracts, begin(2022m1) end(2022m12) sample(org) 
  keep if wageotc > 0 & wageotc != .
  assert age >= 16 & cow1 >= 1 & cow1 <= 5 & emp == 1
  gen byte worker = 1
  lab var worker "Wage-earning worker status"
  lab define l_worker 0 "Not a wage-earner" 1 "Wage-earner"
  label values worker l_worker
  rename wageotc hrwage0
  replace orgwgt = orgwgt / 12

  gen byte imputed = 0
  replace imputed = 1 if paidhre == 1 & a_earnhour == 1
  replace imputed = 1 if paidhre == 0 & a_weekpay == 1

  sum orgwgt
  local benchmark_totalemp = `r(sum)'

  drop if imputed == 1
  sum orgwgt 
  local totalemp = `r(sum)'
  replace orgwgt = orgwgt * `benchmark_totalemp' / `totalemp'

  rename orgwgt perwt0
  rename wbhao racec
  rename hoursu1i uhrswork
  gen pwstate = statefips

  *industry
  gen ind = .
  replace ind = ind17 if year >= 2020
  replace ind = ind12 if year < 2020
  drop ind17 ind12

  gen byte indc=.
  replace indc = 1 if (170<=ind & ind<=490)
  replace indc = 2 if ind==770
  replace indc = 3 if (1070<=ind & ind<=3990)
  replace indc = 4 if (4070<=ind & ind<=4590)
  replace indc = 5 if (4670<=ind & ind<=5790)
  replace indc = 6 if ((6070<=ind & ind<=6390)|(570<=ind & ind<=690))
  replace indc = 7 if (6470<=ind & ind<=6780) 
  replace indc = 8 if (6870<=ind & ind<=7190)
  replace indc = 9 if (7270<=ind & ind<=7570) 
  replace indc = 10 if (7580<=ind & ind<=7790)
  replace indc = 11 if (7860<=ind & ind<=7890) 
  replace indc = 12 if (7970<=ind & ind<=8470)
  replace indc = 13 if (8560<=ind & ind<=8590)
  replace indc = 14 if (8660<=ind & ind<=8670) 
  replace indc = 15 if (8680<=ind & ind<=8690) 
  replace indc = 16 if (8770<=ind & ind<=9290)
  replace indc = 17 if (9370<=ind & ind<=9590)
  replace indc = 18 if (9670<=ind & ind<=9870)
  assert indc != .

  lab var indc "Major Industry"
  #delimit ;
  lab define indc
  1 "Agriculture, fishing, forestry, mining"
  2 "Construction"
  3 "Manufacturing"
  4 "Wholesale trade"
  5 "Retail trade"
  6 "Transportation, warehousing, utilities"
  7 "Information"
  8 "Finance, insurance, real estate"
  9 "Professional, science, management services"
  10 "Administrative, support, waste services"
  11 "Educational services"
  12 "Healthcare, social assistance"
  13 "Arts, entertainment, recreational services"
  14 "Accommodation"
  15 "Restaurants"
  16 "Other services"
  17 "Public administration"
  18 "Active duty military"
  ;
  #delimit cr
  lab val indc indc

  *Tipped workers
  rename occ18 occ
  gen byte tipc = .
  replace tipc = 0 if worker == 1
  replace tipc = 1 if (worker == 1 & inlist(occ,4120,4130) & inlist(ind,8580,8590,8660,8670,8680,8690,8970,8980,8990,9090))
  * pre socc18
  replace tipc = 1 if (worker == 1 & inlist(occ,4040,4060,4110,4400,4500,4510,4520))
  * with socc18
  replace tipc = 1 if (worker == 1 & inlist(occ,4040,4110,4400,4500,4510,4521,4522,4525))

  lab var tipc "Tipped occupations"
  lab define tipc 0 "Not tipped" 1 "Tipped worker" 
  lab val tipc tipc



  keep year month pwstate statefips division hrwage0 perwt0 tipc female racec worker uhrswork indc
  gen monthdate = ym(year, month)

  compress

  save ${input_clean_dir}clean_cps_base.dta, replace

end

clean_cps_base


/*
* merge counterfactual wage growth projections
* use 4% as 2022-2023 growth
gen nom_wage_growth0 = 0.04
local policy_list ""
foreach x of numlist 15/21 {
  foreach y of numlist 2025/2029 {
    local policy_list `policy_list' `x'_`y'
  }
}

foreach policy in `policy_list' {

    preserve 
    *merge in existing and scheduled state minimum wages
    merge m:1 pwstate using "${input_clean_dir}active_state_mins_rtwa_`policy'.dta", assert(3) nogenerate

    compress 
    save ${input_clean_dir}clean_cps_rtwa_`policy'.dta, replace
    
    restore
}
*/
 
