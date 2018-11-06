# Helper functions for phewas digger

#-----------------------------------------------------------------------------
# Help code for testing. 
# Make sure to comment out when running app. 
#-----------------------------------------------------------------------------
# library(tidyverse)
# data <- readRDS(here::here('connect/phewas_digger/data/phenome_data_w_snp.Rds'))
# phewasData <- readRDS(here::here('connect/phewas_digger/data/phewas_data.rds'))




# Combine a phenome and genome dataset and label the resultant snp column: snp. 
merge_phenome_snp <- function(SNP, phenome_data, snp_data){
  
  phenome_data %>% 
    inner_join(
      snp_data %>% 
        filter(snp == SNP) %>% 
        select(IID, snp = copies),
      by = 'IID')
}

# takes a selection dataframe (or NULL) and our phewas table and returns the selected phewas codes from the table. 
getSelectedCodes <- function(selection, phewas_table, just_snps){

  number_phenos_limit <- ifelse(just_snps, MAX_NUM_PHENOS_SNPS, MAX_NUM_PHENOS_ALL)

  # There are three scenarios we have: 
  # 1) no codes are selected at all
  #    - Just subset to a significance threshold for other plots
  noCodesSelected <- length(selection) == 0
  
  # 2) Subset of given codes is selected but is too large to reasonably show ~25 phenotypes
  #    - Take the 25 most significant codes of those selected. 
  subsetTooLarge <- nrow(selection) > number_phenos_limit
  
  # 3) Subset is of reasonable size 
  #    - Take those desired. 
  if(noCodesSelected){
    new_codes <- phewas_table %>% filter(p_val < P_VAL_THRESH)
    
    if(nrow(new_codes) <= 1){
      new_codes <- phewas_table %>% 
        arrange(p_val) %>%
        head(5)
    }
  } else if(subsetTooLarge){
    new_codes <- phewas_table[selection$key,] %>% 
      arrange(p_val) %>%
      head(number_phenos_limit)
  } else {
    new_codes <- phewas_table[selection$key,]
  }
  new_codes
}

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
