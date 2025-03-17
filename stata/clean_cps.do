set more off

global input_clean_dir inputs_clean/

local stata_arguments = subinstr("`0'", "=", "(", .)
local stata_arguments = subinstr("`stata_arguments'", " ", ") ", .)

capture program drop clean_cps_base
program define clean_cps_base
  
  * clean CPS data
  load_epiextracts, begin(2024m1) end(2024m12) sample(org)
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
  rename hoursu1i uhrswork
  gen pwstate = statefips

  *age
  gen teens = age >= 20
  lab var teens "Teenager flag"
  label define l_teens 0 "Teenager" 1 "Age 20 or older"
  label values teens l_teens

  gen agec = .
  replace agec = 0 if age >= 16 & age <= 24
  replace agec = 1 if age >= 25 & age <= 39
  replace agec = 2 if age >= 40 & age <= 54
  replace agec = 3 if age >= 55
  
  lab var agec "Age category"
  label define agec 0 "Age 16 to 24" 1 "Age 25 to 39" 2 "Age 40 to 54" ///
    3 "Age 55 or older"
  label values agec agec

  *race/ethnicity
  rename wbhao racec

  lab var racec "Race / ethnicity"
  #delimit ;
  lab define racec
  1 "White, non-Hispanic" 
  2 "Black, non-Hispanic" 
  3 "Hispanic, any race" 
  4 "Asian, non-Hispanic" 
  5 "Other race/ethnicity"
  ;
  #delimit cr

  label val racec racec

  *Person of color
  gen byte poc = .
  replace poc = 0 if racec == 1
  replace poc = 1 if racec != 1

  lab var poc "Person of color"
  lab define poc 0 "Not person of color" 1 "Person of color"
  label val poc poc

  *Marital and parental status
  gen byte parent=.
  replace parent=1 if ownchild>=1 & ownchild != .
  label var parent "Parent flag"

  gen byte childc=.
  replace childc = 1 if parent==1 & married == 1
  replace childc = 2 if parent==1 & married == 0
  replace childc = 3 if parent~=1 & married == 1
  replace childc = 4 if parent~=1 & married == 0

  lab var childc "Family status"
  #delimit ;
  lab define childc
  1 "Married parent"
  2 "Single parent"
  3 "Married, no children"
  4 "Unmarried, no children"
  ;
  #delimit cr
  lab val childc childc

  *education
  rename educ edc 
  label var edc "Educational attainment"
  #delimit ;
  label define edc 
  1 "Less than high school" 
  2 "High school"
  3 "Some college, no degree"
  4 "Associates degree"
  5 "Bachelors degree or higher" 
  ; 
  #delimit cr
  label val edc edc

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


  *Family income and poverty
  rename faminc orig_faminc
  gen faminc = .
  replace faminc = 0 if orig_faminc >= 1 & orig_faminc <= 7
  replace faminc = 1 if orig_faminc >= 8 & orig_faminc <= 11
  replace faminc = 2 if orig_faminc == 12
  replace faminc = 3 if orig_faminc == 13
  replace faminc = 4 if orig_faminc == 14
  replace faminc = 5 if orig_faminc == 15
  label define l_faminc 0 "Less than $25,000" 1 "$25,000 - $49,999" 2 "$50,000 - $74,999" ///
    3 "$75,000 - $99,999" 4 "$100,000 - $149,999" 5 "$150,000 or more"
  label values faminc l_faminc
  lab var faminc "Family income category"

  gen povstat = .

  gen hourc = .
  replace hourc = 0 if uhrswork < 20 
  replace hourc = 1 if uhrswork >= 20 & uhrswork < 35
  replace hourc = 2 if uhrswork >= 35 & uhrswork != .
  label define l_hourc 0 "Part time (<20 hours per week)" 1 "Mid time (20-34 hours)" 2 "Full time (35+ hours)"
  label values hourc l_hourc
  lab var hourc "Usual weekly work hours category"

    *sector
  gen byte sectc=.
  replace sectc = 1 if cow1 == 4 
  replace sectc = 2 if cow1 == 5
  replace sectc = 3 if cow1 >= 1 & cow1 <= 3

  lab var sectc "Sector"
  #delimit ;
  lab define sectc
  1 "For profit"
  2 "Nonprofit"
  3 "Government"
  4 "Self-employed"
  ;
  #delimit cr
  lab val sectc sectc

  keep year month pwstate statefips division hrwage0 perwt0 tipc female worker uhrswork indc racec poc teens agec childc edc faminc povstat hourc sectc
  gen monthdate = ym(year, month)

  compress

  save ${input_clean_dir}clean_cps_base.dta, replace

end

clean_cps_base


