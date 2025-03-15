create_demo_spreadsheet <- function(microdata,
                                    step,
                                    cpi_step,
                                    cpi_base,
                                    filter_string, 
                                    omitted_groups, 
                                    title, 
                                    output_file) {
  
  data <- create_demo_results(microdata, 
                              step,
                              cpi_step,
                              cpi_base,
                              filter_string, 
                              omitted_groups)
  
  # grab header row numbers too for bold styling loop
  
  # add notes
  source <- paste(
    fmt_txt("Source: ", bold = TRUE),
    fmt_txt("Economic Policy Institute Minimum Wage Simulation Model; see Technical Methodology by Cooper, Mokhiber, and Zipperer (2019).")
  )
  
  notes <- paste(
    fmt_txt("Notes: ", bold = TRUE),
    fmt_txt("Values reflect the population estimated to be affected by the proposed change in the federal minimum wage. Wage changes resulting from scheduled state and local minimum wage laws are accounted for by EPI’s Minimum Wage Simulation Model. Totals may not sum due to rounding. Shares calculated from unrounded values. Directly affected workers will see their wages rise as the new minimum wage rate will exceed their current hourly pay. Indirectly affected workers have a wage rate just above the new minimum wage (between the new minimum wage and 115% of the new minimum). They will receive a raise as employer pay scales are adjusted upward to reflect the new minimum wage. Values marked * cannot be displayed because of sample size restrictions.")
  )
  
  sheet_title <- paste(
    "Demographic characteristics of", 
    title, 
    "workers who would benefit if the federal minimum wage were raised to $17 by 2028"
  )
  
  wb <- wb_workbook() %>% 
    add_demo_summary_worksheet(data, notes, source, sheet_title)
  
  wb_save(wb, output_file)
  
  output_file
}

create_demo_results <- function(microdata, 
                                step,
                                cpi_step,
                                cpi_base,
                                filter_string, 
                                omitted_groups) {
  
  filters <- rlang::parse_exprs(filter_string)
  
  microdata <- microdata %>% 
    filter(!!!filters)
  
  groups_labels %>% 
    discard_at(omitted_groups) %>% 
    imap(~ summary_affected(microdata, step, cpi_step, cpi_base, .y, .x)) %>% 
    list_rbind() %>% 
    misc_cleanup %>%
    select(-matches("^group_")) %>%
    suppress_clean_rename %>% 
    select(-matches("^wage_change")) 
}

add_demo_summary_worksheet <- function(workbook, 
                                       data, 
                                       notes, 
                                       source, 
                                       sheet_title) {
  fill_color <- "ffebf2fa"
  
  data_rows_end <- nrow(data) + 2
  
  workbook <- workbook %>%
    wb_add_worksheet("Results", gridLines = FALSE) %>%
    wb_add_data(x = data, start_row = 2) %>%
    wb_merge_cells(rows = 1, cols = 1:9) %>%
    wb_add_data(x = sheet_title, start_row = 1) %>%
    wb_set_col_widths(cols = 2:9, widths = 15) %>%
    wb_set_col_widths(cols = 1, widths = 45) %>% 
    wb_set_row_heights(rows = 1, heights = 30) %>% 
    wb_set_row_heights(rows = 2, heights = 45) %>% 
    wb_add_cell_style(dims = "A1", horizontal = "center") %>%
    wb_add_cell_style(dims = "B2:I2", wrapText = "1", horizontal = "center") %>% 
    wb_add_cell_style(
      dims = paste0("B2:I", data_rows_end), 
      horizontal = "right"
    ) %>% 
    wb_add_font(dims = "A1", size = "15") %>% 
    wb_add_font(dims = "A2:I2", bold = TRUE) %>%
    wb_add_border(
      dims = paste0("B2:B", data_rows_end), 
      bottom_border = NULL,
      top_border = NULL,
      left_border = "thin",
      right_border = NULL
    ) %>% 
    wb_add_border(
      dims = paste0("G3:G", data_rows_end), 
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
  
  # bold header locations
  bold_rows <- data %>% 
    mutate(
      header_row = Group != "" & `Total workforce` == "", 
      row_number = row_number() + 2
    ) %>% 
    filter(header_row == 1) %>% 
    pull(row_number)
  
  # make headers bold
  for (i in c(3, bold_rows)) {
    workbook <- workbook %>% 
      wb_add_font(dims = paste0("A", i), bold = TRUE, italic = TRUE)
  }
  
  # fill style
  for (i in seq(4, data_rows_end, 2)) {
    dim_range <- paste0("A", i, ":I", i)
    workbook <- workbook %>% 
      wb_add_fill(dims = dim_range, color = wb_color(hex = fill_color))
  }
  
  notes_begin = data_rows_end + 1
  
  workbook <- workbook %>% 
    wb_merge_cells(rows = notes_begin, cols = 1:9) %>%
    wb_add_data(x = notes, start_row = notes_begin) %>% 
    wb_add_cell_style(dims = paste0("A", notes_begin), wrapText = "1") %>% 
    wb_set_row_heights(rows = notes_begin, heights = 65) %>% 
    wb_merge_cells(rows = notes_begin + 1, cols = 1:9) %>% 
    wb_add_cell_style(dims = paste0("A", notes_begin + 1), wrapText = "1") %>% 
    wb_add_data(x = source, start_row = notes_begin + 1)
  
  workbook
}