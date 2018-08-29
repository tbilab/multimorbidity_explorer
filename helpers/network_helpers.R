# Helper functions related to the networks module
# color_palette <- makeDescriptionPalette(phecode_info)
# takes a subset of the individual data along with phewas results
# and returns a set of network data in the form of edges and vertices
# as required by network3d
makeNetworkData <- function(
  data, 
  phecode_info, 
  inverted_codes, 
  color_palette, 
  case_size = 0.1, 
  code_size = 0.3,
  no_copies = '#bdbdbd', 
  one_copy = 'orangered',
  two_copies = 'red'
){
  
  # get rid of superfluous columns so we just have phenotypes
  data_small <- data %>%
    select(-IID, -snp)
  
  n_phenos <- data_small %>% ncol()
  n_cases <- data_small %>% nrow()
  
  pheno_names <- colnames(data_small) 
  case_names <- paste('case', 1:n_cases)
  
  code_to_color <- mutate(
    phecode_info,
    inverted = code %in% inverted_codes
  ) %>% 
    select(code, category, tooltip, inverted) %>% 
    filter(code %in% pheno_names) %>% 
    inner_join(color_palette %>% mutate(description = as.character(description)), by = c('category' = 'description')) %>%
    select(name = code, color, tooltip, inverted)
  
  vertices <- data_frame(
    index = 1:(n_cases + n_phenos),
    snp_status = c(data$snp, rep(0, n_phenos)),
    name = c(case_names, pheno_names)
  ) %>% 
    left_join(code_to_color, by = 'name') %>% 
    mutate(
      color = case_when(
        snp_status == 1 ~ one_copy,
        snp_status == 2 ~ two_copies,
        is.na(color) ~ no_copies,
        TRUE ~ color
      ),
      size = ifelse(str_detect(name, 'case'), case_size, code_size),
      selectable = !str_detect(name, 'case'),
      id = index
    ) 
  
  colnames(data_small) <- (n_cases + 1):(n_cases + n_phenos)
  
  edges <- data_small %>% 
    mutate(case = as.character(1:n())) %>% 
    gather(code, connected, -case) %>% 
    filter(connected == 1) %>% 
    select(-connected, source = case, target = code)
  
  
  list(
    edges = edges,
    vertices = vertices
  )
}