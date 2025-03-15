convert_from_dta <- function(microdata_dta) {
  haven::read_dta(microdata_dta) 
  
  # %>% 
  #   mutate(across(where(is.numeric), type_convert_labels))
}

prep_acs_results <- function(acs_microdata, cps_microdata) {
  cps_count <- cps_microdata %>% 
    select(matches("^perwt")) %>% 
    summarize(across(everything(), sum)) %>% 
    pivot_longer(everything()) %>% 
    mutate(step = as.numeric(str_sub(name, 6)))
  
  steps <- cps_count %>% 
    pull(value) %>% 
    length() - 1
  
  # scale weights to cps data
  for (i in 0:steps) {
    cps_total <- cps_count %>% 
      filter(step == i) %>% 
      pull(value)
    
    acs_var <- paste0("perwt", i)
    
    acs_total <- acs_microdata %>% 
      summarize(sum(.data[[acs_var]])) %>% 
      pull()
    
    acs_microdata <- acs_microdata %>% 
      mutate({{acs_var}} := cps_total / acs_total * .data[[acs_var]])
  }
  
  acs_microdata <- acs_microdata %>% 
    # mark as not directly affected those with no wage change
    repair_directly_affected() %>% 
    # mark as not indirectly affected those with small wage change
    repair_indirectly_affected() %>% 
    mutate(all = haven::labelled(1, c("All workers" = 1)))
    
  acs_microdata
    
}


# a small number of workers are being marked as directly affected 
# but then see no wage change. maybe related to subminimum wage issues
# mark these obs as not directly affected
# create new direct{step} column
repair_direct_step <- function(data, step) {
  direct_var_name <- paste0("direct", step)
  dwage_var_name <- paste0("d_wage", step)
  
  data %>% 
    mutate("{direct_var_name}" := if_else(
      .data[[direct_var_name]] == 1 & is.na(.data[[dwage_var_name]]),
      0,
      .data[[direct_var_name]]
    )) %>% 
    select(all_of(direct_var_name))
}

# modify all direct{step} columns in original data
repair_directly_affected <- function(data) {
  direct_colnames <- data %>% 
    select(matches("^direct")) %>% 
    colnames() 
  
  steps <- length(direct_colnames)
  
  repaired_columns <- map(1:steps, ~ repair_direct_step(data, .x)) %>% 
    list_cbind()
  
  data %>% 
    select(-all_of(direct_colnames)) %>% 
    bind_cols(repaired_columns)
}

# some indirectly affected receive very small wage increase
# mark those with wage increase < 5 cents as not indirectly affected
# create new direct{step} column
repair_indirect_step <- function(data, step) {
  indirect_var_name <- paste0("indirect", step)
  dwage_var_name <- paste0("d_wage", step)
  
  data %>% 
    mutate("{indirect_var_name}" := if_else(
      .data[[indirect_var_name]] == 1 & .data[[dwage_var_name]] < 0.05,
      0,
      .data[[indirect_var_name]]
    )) %>% 
    select(all_of(indirect_var_name))
}

# modify all direct{step} columns in original data
repair_indirectly_affected <- function(data) {
  indirect_colnames <- data %>% 
    select(matches("^indirect")) %>% 
    colnames() 
  
  steps <- length(indirect_colnames)
  
  repaired_columns <- map(1:steps, ~ repair_indirect_step(data, .x)) %>% 
    list_cbind()
  
  data %>% 
    select(-all_of(indirect_colnames)) %>% 
    bind_cols(repaired_columns)
}