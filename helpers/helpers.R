# Helper functions for phewas digger

#-----------------------------------------------------------------------------
# Help code for testing. 
# Make sure to comment out when running app. 
#-----------------------------------------------------------------------------
# library(tidyverse)
# data <- readRDS(here::here('connect/phewas_digger/data/phenome_data_w_snp.Rds'))
# phewasData <- readRDS(here::here('connect/phewas_digger/data/phewas_data.rds'))


warn_about_selection <- function(){
  showModal(modalDialog(
    title = "Too many codes removed",
    "You need to leave at least two codes for the app to visualize. Try adding some codes back.",
    easyClose = TRUE
  ))
}

check_network_selection <- function(selection_array){
  if(length(selection_array) < 2){
    warn_about_selection()
  }
}

# Print big numbers with commas for readibility
commify <- . %>% format(big.mark = ',', scientific = FALSE, trim = TRUE)
