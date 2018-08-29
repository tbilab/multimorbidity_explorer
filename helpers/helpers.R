# Helper functions for phewas digger

#-----------------------------------------------------------------------------
# Help code for testing. 
# Make sure to comment out when running app. 
#-----------------------------------------------------------------------------
# library(tidyverse)
# data <- readRDS(here::here('connect/phewas_digger/data/phenome_data_w_snp.Rds'))
# phewasData <- readRDS(here::here('connect/phewas_digger/data/phewas_data.rds'))

normalizePhecode <- function(codes){
  sprintf('%3.2f', as.numeric(codes)) %>% 
    str_pad(6, side = "left", pad = "0") 
}

subsetToCodes <- function(data, desiredCodes, codes_to_invert = c()){

  # are we going to invert any of these codes?
  inverting_codes <- length(codes_to_invert) > 0;
  
  data[,c('IID', 'snp',desiredCodes)] %>% 
    tidyr::gather(code, value, -IID, -snp) %>% {
      if(inverting_codes){
        left_join(., 
            data_frame(code = codes_to_invert, invert = TRUE),
            by = 'code'
          )
      } else {
        mutate(., invert = FALSE)
      }
    } %>% 
    mutate(
      value = as.numeric(value), #gets mad when value is an integer, so just in case make sure to force it to double. 
      value = case_when(
        value == 1 & invert ~ 0,
        value == 0 & invert ~ 1,
        is.na(value) ~ 0, # unknowns always are 'nos'
        TRUE ~ value
      )
    ) %>% 
    group_by(IID) %>%
    mutate(total_codes = sum(value)) %>%
    ungroup() %>%
    filter(total_codes > 0) %>%
    select(-total_codes, -invert) %>%
    spread(code, value)
}


# Make a standardized color pallete for the phenotype categories
makeDescriptionPalette <- function(phecode_info){
  unique_descriptions <- phecode_info$category %>% unique()
  
  
  palette <- data_frame(
    description = unique_descriptions,
    color = CATEGORY_COLORS %>% head(length(unique_descriptions))
  )
  
  palette_array <- palette$color # turn dataframe into a named array for ggplot scale
  names(palette_array) <- palette$description
  
  list(
    palette = palette,
    named_array = palette_array
  )
}



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
