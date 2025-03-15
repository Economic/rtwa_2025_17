create_state_results <- function(microdata, step, cpi_step, cpi_base) {
  state_codes <- tigris::fips_codes %>% 
    distinct(state, state_code, state_name) %>% 
    transmute(
      state_abb = state,
      state_fips = as.numeric(state_code),
      state_name
    ) %>% 
    filter(state_fips <= 56) %>% 
    as_tibble()
    
  us_results <- groups_labels %>% 
    imap(~ summary_affected(microdata, step, cpi_step, cpi_base, .y, .x)) %>% 
    list_rbind() %>% 
    mutate(state_fips = 0, state_abb = "US", state_name = "United States")
  
  # state tables
  microdata %>%
    rename(state_fips = statefips) %>%
    nest_by(state_fips) %>%
    mutate(group_analysis = list(
      imap(groups_labels, 
           ~ summary_affected(data, step, cpi_step, cpi_base, .y, .x))
    )) %>%
    reframe(list_rbind(group_analysis)) %>%
    full_join(state_codes, by = "state_fips") %>% 
    bind_rows(us_results) %>%
    misc_cleanup %>%
    select(-matches("^group_")) %>%
    suppress_clean_rename
}
