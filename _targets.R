## Load your packages, e.g. library(targets).
source("./packages.R")

## Load your R files
lapply(list.files("./R", full.names = TRUE), source)

tar_assign({
  dofile_clean_state_mw = tar_file("stata/clean_state_mw.do")
  dofile_clean_pop_proj = tar_file("stata/clean_pop_projections.do")
  dofile_clean_cpi_proj = tar_file("stata/clean_cpi_projections.do")
  dofile_clean_policy_schedules = tar_file("stata/clean_policy_schedules.do")
  dofile_clean_cps = tar_file("stata/clean_cps.do")
  dofile_prep_acs = tar_file("stata/prep_acs.do")
  dofile_acs_state = tar_file("stata/acs_state.do")
  dofile_acs_wage_impute = tar_file("stata/impute_wages_cpsloc.do")
  dofile_clean_acs = tar_file("stata/clean_acs.do")
  dofile_run_model = tar_file("stata/run_model.do")

  # do-file data inputs
  # from EPI EARN projections
  state_mw_csv = tar_file("inputs_raw/mw_projections_20250315_state.csv")
  state_tipmw_csv = tar_file("inputs_raw/tipmw_projections_20250315_state.csv")
  # from CBO
  cpi_proj_csv = tar_file("inputs_raw/CPI_projections_1_2025.csv")
  # Census somewhere?
  pop_proj_csv = tar_file("inputs_raw/pop_projections_8_2020.csv")
  # scenario inputs
  policy_schedules_csv = tar_file("inputs_raw/all_scenarios.csv")
  acs_ipums_raw = tar_file("inputs_raw/usa_00084.dta.gz")
  
  # clean cps microdata
  cps_base = do_file_target(
    dofile_clean_cps,
    .outputs = "inputs_clean/clean_cps_base.dta"
  ) |> 
    tar_file()

  # total wage and salary benchmark from CPS
  cps_emp_benchmark = read_dta(cps_base) |> 
    summarize(sum(perwt0)) |> 
    pull() |> 
    tar_target()

  # prep acs data
  acs_prep = do_file_target(
    dofile_prep_acs,
    acs_raw_file = acs_ipums_raw,
    acs_raw_file_base = fs::path_ext_remove(acs_ipums_raw),
    .outputs = "inputs_clean/acs_prep.dta",
    .remove_log = F
  ) |> 
    tar_file()

  acs_state_wages = do_file_target(
    dofile_acs_state,
    acs_prep_file = acs_prep,
    acs_impute_do_file = dofile_acs_wage_impute,
    .outputs = "inputs_clean/acs_state.dta"
  ) |> 
    tar_file()

  acs_state_base = do_file_target(
    dofile_clean_acs,
    acs_raw_file = acs_state_wages,
    cps_emp_benchmark = cps_emp_benchmark,
    geo = "state",
    .outputs = "inputs_clean/clean_acs_state_base.dta"
  ) |> 
    tar_file()

  # clean state-level mw projections
  state_mw_data = do_file_target(
    dofile_clean_state_mw,
    mw_csv = state_mw_csv,
    tipmw_csv = state_tipmw_csv,
    .outputs = "inputs_clean/state_mins.dta",
    .remove_log = F
  ) |> 
    tar_file()

  # clean cpi projections
  cpi_proj_data = do_file_target(
    dofile_clean_cpi_proj,
    cpi_csv = cpi_proj_csv,
    .outputs = "inputs_clean/cpi_projections_1_2025.dta"
  ) |> 
    tar_file()
  
  # clean pop projections
  pop_proj_data = do_file_target(
    dofile_clean_pop_proj,
    pop_csv = pop_proj_csv,
    .outputs = "inputs_clean/pop_projections_8_2020.dta"
  ) |> 
    tar_file()

  # clean scenario inputs
  policy_schedules = do_file_target(
    dofile_clean_policy_schedules,
    scenarios_csv = policy_schedules_csv,
    .outputs = "inputs_clean/all_scenarios.dta"
  ) |> 
    tar_file()

  # run CPS model
  acs_rtwa_17_2030 = do_file_target(
    dofile_run_model,
    microdata_file = acs_state_base,
    data_stub = "acs",
    policy_name = "rtwa_17_2030",
    policy_schedule_file = policy_schedules,
    cpi_file = cpi_proj_data,
    pop_file = pop_proj_data,
    state_mw_file = state_mw_data,
    #local_correction = 1,
    .outputs = "outputs/model_run_microdata_acs_rtwa_17_2030.dta",
    .remove_log = F
  ) |> 
    tar_file()

  # run CPS model
  cps_rtwa_17_2030 = do_file_target(
    dofile_run_model,
    microdata_file = cps_base,
    data_stub = "cps",
    policy_name = "rtwa_17_2030",
    policy_schedule_file = policy_schedules,
    cpi_file = cpi_proj_data,
    pop_file = pop_proj_data,
    state_mw_file = state_mw_data,
    .outputs = "outputs/model_run_microdata_cps_rtwa_17_2030.dta"
  ) |> 
    tar_file()

  results_cps_raw_microdata = read_dta(cps_rtwa_17_2030) |> 
    repair_directly_affected() |> 
    repair_indirectly_affected() |> 
    mutate(all = haven::labelled(1, c("All workers" = 1))) |> 
    tar_parquet()

  results_acs_raw_microdata = read_dta(acs_rtwa_17_2030) |> 
    repair_directly_affected() |> 
    repair_indirectly_affected() |> 
    mutate(all = haven::labelled(1, c("All workers" = 1))) |> 
    tar_parquet()

  summary_stat_cps = results_cps_raw_microdata |>
    summarize(sum((direct6 == 1 | indirect6 == 1) * perwt6)) |> 
    tar_target()

  summary_stat_acs = results_acs_raw_microdata |>
    summarize(sum((direct6 == 1 | indirect6 == 1) * perwt6)) |> 
    tar_target()

  results_acs_state_summary = create_state_results(
    results_acs_raw_microdata, 
    step = 6,
    cpi_step = 358.205,
    cpi_base = 319.537
  ) |> 
    tar_target()

  results_cps_state_summary = create_state_results(
    results_cps_raw_microdata, 
    step = 6,
    cpi_step = 358.205,
    cpi_base = 319.537
  ) |> 
    tar_target()

  # create state-specific and national tables
  spreadsheet_state = create_state_spreadsheet(
    results_acs_state_summary, 
    "outputs/rtwa_17_2025_state_tables.xlsx"
  ) |> tar_file()

})

