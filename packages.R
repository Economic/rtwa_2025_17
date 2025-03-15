library(conflicted)
library(targets)
library(tarchetypes)

# conflicts
conflict_prefer("filter", "dplyr", quiet = TRUE)

# packages for this analysis
suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(openxlsx2)
})

