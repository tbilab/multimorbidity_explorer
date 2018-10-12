# Takes data in the form the app gets it in and turns it into a text file that can be used
# for the bipartite clustering methods. 

# testing main app module in own shiny app.
source(here::here('helpers/load_libraries.R'))
source(here('helpers/merge_phenome_genome.R')) 


snp_name <- 'rs5908'


convert_to_text_data <- function(snp_name, num_cases = 4000){
  base_dir <- glue('data/preloaded/{snp_name}') %>% here()
  
  phewas_data <- glue('{base_dir}/phewas_results.csv') %>% read_csv()
  phenome_raw <-  here('data/preloaded/id_to_code.csv') %>% read_csv()
  genome_raw <- glue('{base_dir}/id_to_snp.csv') %>% read_csv()
  colnames(genome_raw)[2] <- 'snp'
  
  
  individual_data <- merge_phenome_genome(phenome_raw, genome_raw)
  
  get_description <- . %>%
    str_extract('<i>Description:</\\i> .*') %>%
    str_remove_all('<i>Description:</\\i> ') %>%
    str_remove(' </br>') %>%
    str_replace_all(' ', '_')
  
  code_to_description <- phewas_data %>% 
    mutate(description = tooltip %>% get_description()) %>% 
    select(code, description)
  
  gathered_ind_data <- individual_data %>% 
    filter(snp != 0) %>% 
    select(-snp) %>% 
    gather(code, value, -IID) %>% 
    filter(value != 0) %>% 
    left_join(code_to_description, by = 'code') %>% 
    group_by(IID) %>% 
    summarise(phenotypes = paste(description, collapse = ' '))
  
  if(nrow(gathered_ind_data) > num_cases){
    gathered_ind_data <- gathered_ind_data %>% sample_n(num_cases)
  }
  # write phenotype vectors to a text file
  fileConn<-file(here(glue("data/text_data/{snp_name}_phenomes.txt")))
  
  gathered_ind_data$phenotypes %>% 
    writeLines(fileConn)
  
  close(fileConn)
  
  fileConn<-file(here(glue("data/text_data/{snp_name}_case_names.txt")))
  
  gathered_ind_data$IID %>% 
    writeLines(fileConn)
  
  close(fileConn)
}

convert_to_text_data('rs5908')
convert_to_text_data('rs45489199')
convert_to_text_data('rs13283456')
