library(here)
library(magrittr)
library(plotly)
library(r2d3)
library(network3d)

source(here('helpers/constants.R')) # everything defined here is IN UPPERCASE ONLY
source(here('helpers/input_checker_functions.R'))


options(shiny.maxRequestSize=30*1024^2) # increase size of files we can take uploaded to 30 megs.

data_loading_UI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(
            ns("cachedDataset"), "Preloaded dataset:",
            c(
              "rs13283456" = 'data/preloaded_rs13283456.rds'
            )
          ),
          actionButton(ns('preLoadedData'), 'Use preloaded data'),
          hr(),
          h3('Load your data'),
          fileInput(ns("phewas"), "Phewas results file",
                    accept = ACCEPTED_FORMATS
                    
          ),
          fileInput(ns("genome"), "Id to SNP file",
                    accept = ACCEPTED_FORMATS
                    
          ),
          fileInput(ns("phenome"), "ID to phenome file",
                    accept = ACCEPTED_FORMATS
          ),
          shinyjs::hidden(
            actionButton(ns("goToApp"), "Enter App")
          )
        ),
        mainPanel(
          includeMarkdown(here("www/data_instructions.md"))
        )
      )
    )
  )
}

data_loading <- function(input, output, session) {
  #----------------------------------------------------------------
  # Reactive Values based upon user input
  #----------------------------------------------------------------
  print('running loading module!')
  app_data <- reactiveValues( 
    phenome_raw = NULL,
    genome_raw = NULL, 
    phewas_raw = NULL, 
    data_loaded = FALSE,         # has the user uploaded all their data and the app processed it?
    individual_data = NULL,      # holds big dataframe of individual level data
    phewas_data = NULL,          # dataframe of results of univariate statistical tests
    category_colors = NULL,      # Object containing color coading info for plots
    snp_name = NULL              # Name of the current snp being looked at. 
  )

  observeEvent(input$genome, {
    
    tryCatch({
      good_genome_file <- read_csv(input$genome$datapath) %>% 
        checkGenomeFile()  
      
      app_data$snp_name <- good_genome_file$snp_name
      app_data$genome_raw <- good_genome_file$data
      
    },
    error = function(message){
      print(message)
      showModal(modalDialog(
        p("There's something wrong with the format of your genome data. Make sure the file has two columns. One with the title IID with unique id and one with the title of your snp containing copies of the minor allele."),
        strong('Error message:'),
        code(message),
        title = "Data format problem",
        easyClose = TRUE
      ))
    })
  })
  
  observeEvent(input$phewas, {
    
    tryCatch({
      app_data$phewas_raw <- read_csv(input$phewas$datapath) %>% checkPhewasFile()
    },
    error = function(message){
      print(message)
      showModal(modalDialog(
        p("There's something wrong with the format of your results data."),
        strong('Error message:'),
        code(message),
        title = "Data format problem",
        easyClose = TRUE
      ))
    })
  })
  
  observeEvent(input$phenome, {
    tryCatch({
      app_data$phenome_raw <- read_csv(input$phenome$datapath) %>% checkPhenomeFile()
    },
    error = function(message){
      print(message)
      showModal(modalDialog(
        p("There's something wrong with the format of your phenome data."),
        strong('Error message:'),
        code(message),
        title = "Data format problem",
        easyClose = TRUE
      ))
    })
  })
  #----------------------------------------------------------------
  # Data Loading Logic
  #----------------------------------------------------------------
  # Watches for all files to be loaded and then triggers.
  observeEvent({input$phewas; input$genome; input$phenome},{
    req(app_data$phewas_raw, app_data$genome_raw, app_data$phenome_raw)
    
    withProgress(message = 'Loading data', value = 0, {
      # read files into R's memory
      incProgress(1/4, detail = "Reading in uploaded files")
      
      phenome <- app_data$phenome_raw
      genome  <- app_data$genome_raw
      phewas  <- app_data$phewas_raw
      
      # first spread the phenome data to a wide format
      incProgress(2/4, detail = "Processing phenome data")
      individual_data <- phenome %>% 
        mutate(value = 1) %>% 
        spread(code, value, fill = 0) 
      
      # Next merge with genome data
      incProgress(3/4, detail = "Merging phenome and genome data")
      individual_data <- individual_data %>%
        left_join(genome, by = 'IID') %>% 
        mutate(snp = ifelse(is.na(snp), 0, snp))
      
      # These are codes that are not shared between the phewas and phenome data. We will remove them 
      # from either. 
      phenome_cols <- colnames(individual_data)
      bad_codes <- setdiff(phenome_cols %>% head(-1) %>% tail(-1), unique(phewas$code))
      app_data$phewas_data <- phewas %>% # remove bad codes from phewas
        filter(!(code %in% bad_codes))
      
      # remove bad codes from individual data
      app_data$individual_data<- individual_data[,-which(phenome_cols %in% bad_codes)]
      
      # Color palette for phecode categories
      app_data$category_colors <- makeDescriptionPalette(app_data$phewas_data)
      
      # Sending to app
      incProgress(4/4, detail = "Sending to application!")
      
      # shinyjs::show("goToApp")
      app_data$data_loaded <- TRUE
    }) # end progress messages
  })
  
  observeEvent(input$goToApp,{
    app_data$data_loaded <- TRUE
  })
  
  observeEvent(input$preLoadedData,{
    print('running preloaded data button function')
    selected_file <- input$cachedDataset
    
    withProgress(message = 'Loading cached data', value = 0, {
      
      incProgress(1/3, detail = "Reading cached file to memory")
      cached_data <- read_rds(here::here(selected_file))
      
      incProgress(2/3, detail = "Loading data into application state")
      app_data$individual_data <- cached_data$individual_data 
      app_data$category_colors <- cached_data$category_colors 
      app_data$phewas_data <- cached_data$phewas_data 
      app_data$snp_name <- cached_data$snp_name 
      
      incProgress(3/3, detail = "Starting app")
      
      app_data$data_loaded <- TRUE
    }) # end progress
  })
  
  return(
    reactive({
      if(app_data$data_loaded){
        list(
          individual_data = app_data$individual_data,
          category_colors = app_data$category_colors,
          phewas_data = app_data$phewas_data,
          snp_name = app_data$snp_name
        )  
      } else {
        NULL
      }
    })
  )
}

