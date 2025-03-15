create_state_spreadsheet <- function(data, filename) {
  # add notes
  source <- paste(
    fmt_txt("Source: ", bold = TRUE),
    fmt_txt("Economic Policy Institute Minimum Wage Simulation Model; see Technical Methodology by Cooper, Mokhiber, and Zipperer (2019).")
  )
  
  notes <- paste(
    fmt_txt("Notes: ", bold = TRUE),
    fmt_txt("Values reflect the population estimated to be affected by the proposed change in the federal minimum wage. Wage changes resulting from scheduled state and local minimum wage laws are accounted for by EPI’s Minimum Wage Simulation Model. Totals may not sum due to rounding. Shares calculated from unrounded values. Directly affected workers will see their wages rise as the new minimum wage rate will exceed their current hourly pay. Indirectly affected workers have a wage rate just above the new minimum wage (between the new minimum wage and 115% of the new minimum). They will receive a raise as employer pay scales are adjusted upward to reflect the new minimum wage. Values marked * cannot be displayed because of sample size restrictions.")
  )
  
  wb <- wb_workbook() %>% 
    add_state_intro_worksheet() %>% 
    add_state_summary_worksheet(data, notes, source)
  
  state_names <- data %>% 
    pull(state_name) %>% 
    unique() %>% 
    # remove some states from detailed summary due to small affected #s
    str_subset("California|Hawaii|District|Washington", negate = TRUE) %>% 
    # place US total at top by removing, alphabetizing, and then adding back in
    str_subset("United States", negate = TRUE) %>% 
    sort() %>% 
    c("United States", .)
  
  for (i in state_names) {
    wb <- wb %>% 
      add_state_worksheet(i, data, notes, source)
  }
  
  wb_save(wb, filename)
  
  filename
}

add_state_worksheet <- function(workbook, state, data, notes, source) {
  state_data <- data %>% 
    filter(state_name == state) %>% 
    select(
      -matches("^state_"), 
      -wage_change_total_ann,
      -wage_change_avg_ann,
      -wage_change_affected_pct
    )
  
  sheet_table_title <- paste(
    "Demographic characteristics of", 
    state, 
    "workers who would benefit if the federal minimum wage were raised to $17 by 2028"
  )
  
  if (state == "United States") worksheet_name = "U.S. Total"
  else worksheet_name = state
  
  fill_color <- "ffebf2fa"
  workbook <- workbook %>%
    wb_add_worksheet(worksheet_name, gridLines = FALSE) %>%
    wb_add_data(x = state_data, start_row = 2) %>%
    wb_merge_cells(rows = 1, cols = 1:9) %>%
    wb_add_data(x = sheet_table_title, start_row = 1) %>%
    wb_set_col_widths(cols = 2:9, widths = 15) %>%
    wb_set_col_widths(cols = 1, widths = 45) %>% 
    wb_set_row_heights(rows = 1, heights = 30) %>% 
    wb_set_row_heights(rows = 2, heights = 45) %>% 
    wb_add_cell_style(dims = "A1", horizontal = "center") %>%
    wb_add_cell_style(dims = "B2:I2", wrapText = "1", horizontal = "center") %>% 
    wb_add_cell_style(dims = "B2:I75", horizontal = "right") %>% 
    wb_add_font(dims = "A1", size = "15") %>% 
    wb_add_font(dims = "A2:I2", bold = TRUE) %>%
    wb_add_font(dims = "A3", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A4", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A7", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A15", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A24", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A29", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A35", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A42", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A47", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A51", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A69", bold = TRUE, italic = TRUE) %>% 
    wb_add_font(dims = "A72", bold = TRUE, italic = TRUE) %>% 
    wb_add_border(
      dims = "B2:B75", 
      bottom_border = NULL,
      top_border = NULL,
      left_border = "thin",
      right_border = NULL
    ) %>% 
    wb_add_border(
      dims = "G3:G75", 
      bottom_border = NULL,
      top_border = NULL,
      left_border = "thin",
      right_border = "thin"
    ) %>% 
    wb_add_border(
      dims = "A2:I2", 
      bottom_border = "thick",
      top_border = "medium",
      left_border = NULL,
      right_border = NULL
    ) %>% 
    wb_add_border(
      dims = "B2", 
      bottom_border = "thick",
      top_border = "medium",
      left_border = "thin",
      right_border = NULL
    ) 
  
  # fill style
  for (i in seq(4, 74, 2)) {
    dim_range <- paste0("A", i, ":I", i)
    workbook <- workbook %>% 
      wb_add_fill(dims = dim_range, color = wb_color(hex = fill_color))
  }
  
  workbook <- workbook %>% 
    wb_merge_cells(rows = 76, cols = 1:9) %>%
    wb_add_data(x = notes, start_row = 76) %>% 
    wb_add_cell_style(dims = "A76", wrapText = "1") %>% 
    wb_set_row_heights(rows = 76, heights = 65) %>% 
    wb_merge_cells(rows = 77, cols = 1:9) %>% 
    wb_add_cell_style(dims = "A77", wrapText = "1") %>% 
    wb_add_data(x = source, start_row = 77)
  
  workbook
  
}

add_state_intro_worksheet <- function(workbook) {
  workbook %>% 
    wb_add_worksheet("README") %>%
    wb_add_data(x = "State-specific estimates of the Raise the Wage Act of 2023", start_row = 1) %>% 
    wb_add_data(x = "Economic Policy Institute, July 2023", start_row = 2) %>% 
    wb_add_data(x = "This spreadsheet contains state-specific estimates of the effects of the Raise the Wage Act of 2023, as estimated by the Economic Policy Institute Minimum Wage Simulation Model.", start_row = 4) %>% 
    wb_add_data(x = "Detailed estimates for California, District of Columbia, Hawaii, and Washington are unavailable because of the small number of workers affected by the policy in these states.", start_row = 6) %>% 
    wb_add_data(x = "CITATIONS", start_row = 8) %>% 
    wb_add_data(x = "Please cite the estimates in this spreadsheet as \"Estimated effects of Raise the Wage Act of 2023,\" Economic Policy Institute Minimum Wage Simulation Model, July 2023.", start_row = 9) %>% 
    wb_add_data(x = "ASSUMPTIONS", start_row = 11) %>% 
    wb_add_data(x = "The estimates are for the year 2028, when the policy's regular minimum wage is $17 and the tipped minimum wage is $15.", start_row = 12) %>% 
    wb_add_data(x = "The underlying wage distribution is based on the 2022 Current Population Survey.", start_row = 13) %>%
    wb_add_data(x = "The simulation assumes nominal wage growth will be at a 5.0% annual rate between 2022 and 2023, and at a annual rate of 0.5% plus projected CPI growth in subsequent years.", start_row = 14) %>% 
    wb_add_data(x = "The simulation accounts for estimated effects of projected state and local minimum wages between 2023 and 2028.", start_row = 15) %>% 
    wb_add_data(x = "DOCUMENTATION", start_row = 17) %>% 
    wb_add_data(x = "To read more about the EPI Minimum Wage Simulation Model, see", start_row = 18) %>% 
    wb_add_data(x = "* the description in Cooper, Mokhiber, Zipperer (2019): https://www.epi.org/publication/minimum-wage-simulation-model-technical-methodology/", start_row = 19) %>% 
    wb_add_data(x = "* a Stata implementation of the simulation model: https://github.com/Economic/min_wage_sim", start_row = 20) %>% 
    wb_add_data(x = "* the code used to produce these estimates: https://github.com/Economic/rtwa_2023_17", start_row = 21) %>% 
    wb_add_font(dims = "A1", size = "15", bold = TRUE) %>% 
    wb_set_col_widths(cols = 1, widths = 175) %>% 
    wb_add_font(dims = "A8", bold = TRUE) %>%
    wb_add_font(dims = "A11", bold = TRUE) %>%
    wb_add_font(dims = "A17", bold = TRUE) 
}

add_state_summary_worksheet <- function(workbook, data, notes, source) {
  
  state_summary_data <- data %>% 
    filter(Group == "All workers") %>% 
    mutate(order = if_else(state_name == "United States", 0, 1)) %>% 
    arrange(order, state_name) %>% 
    select(
      -order, 
      -state_abb, 
      -state_fips, 
      -Group, 
      -`Group's share of total affected`
    ) %>% 
    select(State = state_name, everything()) %>% 
    mutate(State = if_else(State == "United States", "U.S. Total", State)) %>% 
    rename(
      "Total annual wage change (2023$, millions)" = wage_change_total_ann,
      "Average annual wage increase of affected workers (2023$)" = wage_change_avg_ann,
      "Percent change in average annual wages of affected workers" = wage_change_affected_pct
    )
  
  sheet_table_title <- "Summary of effects in 2028 of increasing the minimum wage to $17 by 2028, by state"
  
  fill_color <- "ffebf2fa"
  
  workbook <- workbook %>% 
    wb_add_worksheet("State summary", gridLines = FALSE) %>%
    wb_add_data(x = state_summary_data, start_row = 2) %>%
    wb_merge_cells(rows = 1, cols = 1:11) %>%
    wb_add_data(x = sheet_table_title, start_row = 1) %>%
    wb_set_col_widths(cols = 2:11, widths = 15) %>%
    wb_set_col_widths(cols = 1, widths = 45) %>% 
    wb_set_row_heights(rows = 1, heights = 30) %>% 
    wb_set_row_heights(rows = 2, heights = 60) %>% 
    wb_add_cell_style(dims = "A1", horizontal = "center") %>%
    wb_add_cell_style(dims = "A2:A54", horizontal = "left") %>%
    wb_add_cell_style(dims = "B2:K2", wrapText = "1", horizontal = "center") %>% 
    wb_add_cell_style(dims = "B3:K54", horizontal = "center") %>% 
    wb_add_font(dims = "A1", size = "15") %>% 
    wb_add_font(dims = "A2:K2", bold = TRUE) %>%
    wb_add_border(
      dims = "B2:B54", 
      bottom_border = NULL,
      top_border = NULL,
      left_border = "thin",
      right_border = NULL
    ) %>% 
    wb_add_border(
      dims = "A2:K2", 
      bottom_border = "thick",
      top_border = "medium",
      left_border = NULL,
      right_border = NULL
    ) %>% 
    wb_add_border(
      dims = "B2", 
      bottom_border = "thick",
      top_border = "medium",
      left_border = "thin",
      right_border = NULL
    ) 
  
  # fill style
  for (i in seq(4, 54, 2)) {
    dim_range <- paste0("A", i, ":K", i)
    workbook <- workbook %>% 
      wb_add_fill(dims = dim_range, color = wb_color(hex = fill_color))
  }
  
  workbook <- workbook %>% 
    wb_merge_cells(rows = 55, cols = 1:11) %>%
    wb_add_data(x = notes, start_row = 55) %>% 
    wb_add_cell_style(dims = "A55", wrapText = "1") %>% 
    wb_set_row_heights(rows = 55, heights = 65) %>% 
    wb_merge_cells(rows = 56, cols = 1:11) %>% 
    wb_add_cell_style(dims = "A56", wrapText = "1") %>% 
    wb_add_data(x = source, start_row = 56)
  
  workbook
}

