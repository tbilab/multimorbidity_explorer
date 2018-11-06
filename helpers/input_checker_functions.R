# code to check file inputs to make sure they are what we are looking for. 

# Phenome file check
checkPhenomeFile <- function(phenome){
  # should have two columns: one with title IID and one with title code. 
  columns <- colnames(phenome)
  
  has_IID <- 'IID' %in% columns
  if(!has_IID) stop("Missing IID column.", call. = FALSE)
  
  has_code <- 'code' %in% columns
  if(!has_code) stop("Missing Code column.", call. = FALSE)
  
  phenome
}

# testing function
# phenome <- read_csv(here::here('data/input_data/id_w_codes.csv'))
# phenome_bad <- phenome %>% rename(mycode = code)
# phenome %>% checkPhenomeFile()
# phenome_bad %>% checkPhenomeFile()

checkGenomeFile <- function(genome){
  columns <- colnames(genome)
  
  has_IID <- 'IID' %in% columns
  if(!has_IID) stop("Missing IID column.", call. = FALSE)
  
  two_columns <- length(columns) == 2
  if(!two_columns) stop("File needs to be just two columns.", call. = FALSE)
  
  # grab the name of the snp as the column name
  snp_name <- columns[columns != 'IID']
  
  # rename column containing snp to 'snp' for app 
  colnames(genome)[columns == snp_name] <- 'snp'
  
  # Make sure that the snp copies column is an integer or can be coerced to one. 
  unique_counts <- genome %>% head() %>% .$snp %>% unique()
  if(!all(unique_counts %in% c(0,1,2))){
    stop("Your SNP copies column appears to have values other than 0,1,2.", call. = FALSE)
  }
  
  list(data = genome, snp_name = snp_name)
}

# # Tests
# genome <- read_csv(here::here('data/input_data/id_w_snp.csv'))
# genome_bad <- phenome %>% rename(anID = IID)
# 
# genome %>% checkGenomeFile()
# genome %>% rename(anID = IID) %>% checkGenomeFile()
# genome %>% mutate(rs13283456 = 3) %>% checkGenomeFile()



checkPhewasFile <- function(phewas){
  columns <- colnames(phewas)
  
  has_code <- 'code' %in% columns
  if(!has_code) stop("Missing Code column.", call. = FALSE)
  
  has_category <- 'category' %in% columns
  if(!has_category) stop("Missing Category column", call. = FALSE)
  
  has_pval <- 'p_val' %in% columns
  if(!has_pval) stop("Missing P Value column (p_val)", call. = FALSE)
  
  # Do we have a supplied tooltip already or should we make one from the left over
  # columns?
  has_tooltip <- 'tooltip' %in% columns
  
  if(!has_tooltip){
    phewas <- phewas %>% meToolkit::makeTooltips()
  }
  
  phewas
}

# phewas <- read_csv(here::here('data/input_data/phewas_rs13283456.csv'))
# 
# phewas %>% checkPhewasFile()
# phewas %>% select(-tooltip) %>% checkPhewasFile()
# phewas %>% select(-p_val) %>% checkPhewasFile()
