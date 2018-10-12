source(here('helpers/constants.R')) # everything defined here is IN UPPERCASE ONLY
source(here('helpers/helpers.R')) 
source(here('helpers/merge_phenome_genome.R')) 
source(here('helpers/input_checker_functions.R'))

options(shiny.maxRequestSize=30*1024^2) # increase size of files we can take uploaded to 30 megs.

data_loading_UI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          uiOutput(ns('preloaded_snps')),
          actionButton(ns('preLoadedData'), 'Use preloaded data'),
          hr(),
          h3('Load your data'),
          fileInput(ns("phewas"), "Phewas results file",
                    accept = ACCEPTED_FORMATS
                    
          ),
          fileInput(ns("genome"), "ID to SNP file",
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
  
  # find all the snps we have preloaded
  preloaded_snps <- list.files(here('data/preloaded'), pattern = 'rs') 
  
  output$preloaded_snps <- renderUI({
    selectInput(session$ns("dataset_selection"), "Select a pre-loaded dataset:",
                preloaded_snps
    )
  })

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
  observe({
    req(app_data$phewas_raw, app_data$genome_raw, app_data$phenome_raw)
    
    withProgress(message = 'Loading data', value = 0, {
      # read files into R's memory
      incProgress(1/3, detail = "Reading in uploaded files")

      phenome <- app_data$phenome_raw
      genome  <- app_data$genome_raw
      phewas  <- app_data$phewas_raw
      
      # first spread the phenome data to a wide format
      incProgress(2/3, detail = "Processing phenome data")
      individual_data <- merge_phenome_genome(phenome, genome) 

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
      incProgress(3/3, detail = "Sending to application!")
      
      # shinyjs::show("goToApp")
      app_data$data_loaded <- TRUE
    }) # end progress messages
  })
  
  observeEvent(input$goToApp,{
    app_data$data_loaded <- TRUE
  })
  
  observeEvent(input$preLoadedData,{
    base_dir <- glue('data/preloaded/{input$dataset_selection}') %>% here()
   
    app_data$phewas_raw <- glue('{base_dir}/phewas_results.csv') %>% read_csv()
    app_data$phenome_raw <-  here('data/preloaded/id_to_code.csv') %>% read_csv()
    
    
    genome_file <- glue('{base_dir}/id_to_snp.csv') %>% 
      read_csv() %>% 
      checkGenomeFile()  
    app_data$snp_name <- genome_file$snp_name
    app_data$genome_raw <- genome_file$data
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

