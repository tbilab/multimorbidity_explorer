# function to merge individual level data from a phenome and genome. 

merge_phenome_genome <- function(phenome_data, genome_data){
  phenome_data %>% 
    mutate(value = 1) %>% 
    spread(code, value, fill = 0) %>% 
    left_join(genome_data, by = 'IID') %>% 
    mutate(snp = ifelse(is.na(snp), 0, snp))
}