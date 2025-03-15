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
  dofile_run_model = tar_file("stata/run_model.do")

  # do-file data inputs
  # from EPI EARN projections
  state_mw_csv = tar_file("inputs_raw/mw_projections_state.csv")
  state_tipmw_csv = tar_file("inputs_raw/tipmw_projections_state.csv")
  # from CBO
  cpi_proj_csv = tar_file("inputs_raw/CPI_projections_2_2023.csv")
  # Census somewhere?
  pop_proj_csv = tar_file("inputs_raw/pop_projections_8_2020.csv")
  # scenario inputs
  policy_schedules_csv = tar_file("inputs_raw/all_scenarios.csv")

  # clean state-level mw projections
  state_mw_data = do_file_target(
    dofile_clean_state_mw,
    mw_csv = state_mw_csv,
    tipmw_csv = state_tipmw_csv,
    .outputs = "inputs_clean/state_mins.dta"
  ) |> 
    tar_file()

  # clean cpi projections
  cpi_proj_data = do_file_target(
    dofile_clean_cpi_proj,
    cpi_csv = cpi_proj_csv,
    .outputs = "inputs_clean/cpi_projections_2_2023.dta"
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

  # clean microdata
  cps_base = do_file_target(
    dofile_clean_cps,
    .outputs = "inputs_clean/clean_cps_base.dta"
  ) |> 
    tar_file()

  # run CPS model
  cps_rtwa_17_2028_ofw = do_file_target(
    dofile_run_model,
    microdata_file = cps_base,
    data_stub = "cps",
    policy_name = "rtwa_17_2028_ofw",
    policy_schedule_file = policy_schedules,
    cpi_file = cpi_proj_data,
    pop_file = pop_proj_data,
    state_mw_file = state_mw_data,
    .outputs = "outputs/model_run_microdata_cps_rtwa_17_2028_ofw.dta"
  ) |> 
    tar_file()

  results_cps_raw_microdata = read_dta(cps_rtwa_17_2028_ofw) |> 
    tar_parquet()

})

# list(
#   # do-file targets
#   tar_file(dofile_clean_substate_mw, "stata/clean_substate_mw.do"),
#   tar_file(dofile_clean_state_mw, "stata/clean_state_mw.do"),
#   tar_file(dofile_clean_pop_proj, "stata/clean_pop_projections.do"),
#   tar_file(dofile_clean_cpi_proj, "stata/clean_cpi_projections.do"),
#   tar_file(dofile_clean_policy_schedules, "stata/clean_policy_schedules.do"),
#   tar_file(dofile_clean_cps, "stata/clean_cps.do"),
#   tar_file(dofile_clean_acs, "stata/clean_acs.do"),
#   tar_file(dofile_clean_acs_cd118, "stata/clean_acs_cd118.do"),
#   tar_file(dofile_run_model, "stata/run_model.do"),
  
#   # do-file data inputs
#   # hand-coded by Dave Cooper
#   tar_file(pwpumas_dta, "inputs_raw/pwpumas.dta"),
#   # Geocorr 2022
#   tar_file(geocorr_puma_cd118, "inputs_raw/geocorr2022_puma2012_cd118.csv"),
#   # https://www2.census.gov/programs-surveys/acs/data/2021/CD118_Data_Profiles/ALL_CD%20by%20Nation/
#   tar_file(acs_tables_cd118, "inputs_raw/DP03_1yr_500.csv"),
#   # from EPI EARN projections
#   tar_file(state_mw_csv, "inputs_raw/mw_projections_state.csv"),
#   tar_file(state_tipmw_csv, "inputs_raw/tipmw_projections_state.csv"),
#   # from CBO
#   tar_file(cpi_proj_csv, "inputs_raw/CPI_projections_2_2023.csv"),
#   # Census somewhere?
#   tar_file(pop_proj_csv, "inputs_raw/pop_projections_8_2020.csv"),
#   # scenario inputs
#   tar_file(policy_schedules_csv, "inputs_raw/all_scenarios.csv"),
  
#   # clean state-level mw projections
#   tar_file(
#     state_mw_data, 
#     do_file_target(dofile_clean_state_mw,
#                    mw_csv = state_mw_csv,
#                    tipmw_csv = state_tipmw_csv,
#                    .outputs = "inputs_clean/state_mins.dta")
#   ),
  
#   # clean substate-level mw projections
#   tar_file(
#     substate_mw_data, 
#     do_file_target(dofile_clean_substate_mw,
#                    pumas_dta = pwpumas_dta,
#                    .outputs = "inputs_clean/local_mins.dta")
#   ),
  
#   # clean cpi projections
#   tar_file(
#     cpi_proj_data, 
#     do_file_target(dofile_clean_cpi_proj,
#                    cpi_csv = cpi_proj_csv,
#                    .outputs = "inputs_clean/cpi_projections_2_2023.dta")
#   ),
  
#   # clean pop projections
#   tar_file(
#     pop_proj_data, 
#     do_file_target(dofile_clean_pop_proj,
#                    pop_csv = pop_proj_csv,
#                    .outputs = "inputs_clean/pop_projections_8_2020.dta")
#   ),
  
#   # clean scenario inputs
#   tar_file(
#     policy_schedules, 
#     do_file_target(dofile_clean_policy_schedules,
#                    scenarios_csv = policy_schedules_csv,
#                    .outputs = "inputs_clean/all_scenarios.dta")
#   ),
  
#   # clean microdata
#   tar_file(
#     cps_base, 
#     do_file_target(dofile_clean_cps,
#                    .outputs = "inputs_clean/clean_cps_base.dta")
#   ),
#   tar_file(
#     acs_state_base, 
#     do_file_target(dofile_clean_acs,
#                    geo = "state",
#                    .outputs = "inputs_clean/clean_acs_state_base.dta")
#   ),
#   tar_file(
#     acs_cd118_base,
#     do_file_target(dofile_clean_acs_cd118,
#                    acs_tables_csv = acs_tables_cd118,
#                    puma_cd_csv = geocorr_puma_cd118,
#                    acs_source_dta = acs_state_base,
#                    .outputs = "inputs_clean/clean_acs_cd118_base.dta")
#   ),
  
#   # run CPS model
#   tar_file(
#     cps_rtwa_17_2028_ofw,
#     do_file_target(dofile_run_model,
#                    microdata_file = cps_base,
#                    data_stub = "cps",
#                    policy_name = "rtwa_17_2028_ofw",
#                    policy_schedule_file = policy_schedules,
#                    cpi_file = cpi_proj_data,
#                    pop_file = pop_proj_data,
#                    state_mw_file = state_mw_data,
#                    .outputs = "outputs/model_run_microdata_cps_rtwa_17_2028_ofw.dta")
#   ),
#   # run ACS model
#   tar_file(
#     acs_state_rtwa_17_2028_ofw,
#     do_file_target(dofile_run_model,
#                    microdata_file = acs_state_base,
#                    data_stub = "acs_state",
#                    policy_name = "rtwa_17_2028_ofw",
#                    policy_schedule_file = policy_schedules,
#                    cpi_file = cpi_proj_data,
#                    pop_file = pop_proj_data,
#                    state_mw_file = state_mw_data,
#                    local_mw_file = substate_mw_data,
#                    .outputs = "outputs/model_run_microdata_acs_state_rtwa_17_2028_ofw.dta")
#   ),
#   # run ACS CD 118 model
#   tar_file(
#     acs_cd118_rtwa_17_2028_ofw,
#     do_file_target(dofile_run_model,
#                    microdata_file = acs_cd118_base,
#                    data_stub = "acs_cd118",
#                    policy_name = "rtwa_17_2028_ofw",
#                    policy_schedule_file = policy_schedules,
#                    cpi_file = cpi_proj_data,
#                    pop_file = pop_proj_data,
#                    state_mw_file = state_mw_data,
#                    local_mw_file = substate_mw_data,
#                    .outputs = "outputs/model_run_microdata_acs_cd118_rtwa_17_2028_ofw.dta")
#   ),
  
#   # CR models
#   tar_file(
#     cps_cr_11_2028,
#     do_file_target(dofile_run_model,
#                    microdata_file = cps_base,
#                    data_stub = "cps",
#                    policy_name = "cr_11_2028",
#                    policy_schedule_file = policy_schedules,
#                    cpi_file = cpi_proj_data,
#                    pop_file = pop_proj_data,
#                    state_mw_file = state_mw_data,
#                    .outputs = "outputs/model_run_microdata_cps_cr_11_2028.dta")
#   ),
#   tar_file(
#     acs_state_cr_11_2028,
#     do_file_target(dofile_run_model,
#                    microdata_file = acs_state_base,
#                    data_stub = "acs_state",
#                    policy_name = "cr_11_2028",
#                    policy_schedule_file = policy_schedules,
#                    cpi_file = cpi_proj_data,
#                    pop_file = pop_proj_data,
#                    state_mw_file = state_mw_data,
#                    local_mw_file = substate_mw_data,
#                    .outputs = "outputs/model_run_microdata_acs_state_cr_11_2028.dta")
#   ),
  
#   # convert dta to feather
#   tar_format_feather(
#     results_cps_raw_microdata, 
#     convert_from_dta(cps_rtwa_17_2028_ofw)
#   ),
#   tar_format_feather(
#     results_acs_raw_microdata, 
#     convert_from_dta(acs_state_rtwa_17_2028_ofw)
#   ),
#   tar_format_feather(
#     results_acs_cd118_raw_microdata, 
#     convert_from_dta(acs_cd118_rtwa_17_2028_ofw)
#   ),
#   tar_format_feather(
#     results_cps_raw_microdata_cr, 
#     convert_from_dta(cps_cr_11_2028)
#   ),
#   tar_format_feather(
#     results_acs_raw_microdata_cr, 
#     convert_from_dta(acs_state_cr_11_2028)
#   ),
  
#   # pin ACS workforce totals to ACS and refine model results
#   tar_format_feather(
#     results_acs_refined_microdata, 
#     prep_acs_results(results_acs_raw_microdata, results_cps_raw_microdata)
#   ),
#   tar_format_feather(
#     results_acs_cd118_refined_microdata, 
#     prep_acs_results(results_acs_cd118_raw_microdata, results_cps_raw_microdata)
#   ),
#   tar_format_feather(
#     results_acs_refined_microdata_cr, 
#     prep_acs_results(results_acs_raw_microdata_cr, results_cps_raw_microdata_cr)
#   ),
  
#   # create state-specific results
#   tar_target(
#     results_state_summary, 
#     create_state_results(results_acs_refined_microdata, 
#                          step = 6,
#                          cpi_step = 344.789,
#                          cpi_base = 305.535)
#   ),
  
#   # create state-specific and national tables
#   tar_file(
#     spreadsheet_state,
#     create_state_spreadsheet(results_state_summary, 
#                              "outputs/rtwa_17_2028_state_tables.xlsx")
#   ),
  
#   # create state-specific results for CR
#   tar_target(
#     results_state_summary_cr, 
#     create_state_results(results_acs_refined_microdata_cr, 
#                          step = 5,
#                          cpi_step = 341.011,
#                          cpi_base = 305.535)
#   ),
#   # create state-specific and national tables for CR
#   tar_file(
#     spreadsheet_state_cr,
#     create_state_spreadsheet(results_state_summary_cr, 
#                              "outputs/cr_11_2028_state_tables.xlsx")
#   ),
  
#   # create CD118-specific results
#   tar_target(
#     results_cd118_summary,
#     create_cd118_results(
#       cd_microdata = results_acs_cd118_refined_microdata,
#       state_microdata = results_acs_refined_microdata
#     )
#   ),
  
#   # create CD118-specific tables
#   tar_file(
#     spreadsheet_cd118,
#     create_cd_spreadsheet(results_cd118_summary, 
#                           "outputs/rtwa_17_2028_cd118_tables.xlsx")
#   ),
  
#   # create additional demographic cuts
#   tar_file(
#     spreadsheet_female,
#     create_demo_spreadsheet(
#       results_acs_refined_microdata,
#       step = 6,
#       cpi_step = 344.789,
#       cpi_base = 305.535,
#       filter_string = "female == 1",
#       omitted_groups = "female",
#       title = "women",
#       output_file = "outputs/rtwa_17_2028_female_tables.xlsx"
#     )
#   )

# )


# tar_read(results_cps_raw_microdata)  |>  repair_directly_affected()  |>  repair_indirectly_affected()  |> summarize(sum((direct6 == 1 | indirect6 == 1)*perwt6))