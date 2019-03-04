source(here('helpers/constants.R')) # everything defined here is IN UPPERCASE ONLY
source(here('modules/network_plots_module.R'))
source(here('modules/phewas_plot_table_module.R'))


main_app_UI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head( tags$link(rel = "stylesheet", type = "text/css", href = "custom.css") ),
    fluidRow(
      column(
        width = 5,
        phewas_plot_table_UI('phewas_plot_table', ns),
        meToolkit::upset_UI('upsetPlotV2', ns)
      ),
      column(
        width = 7,
        meToolkit::infoPanel_UI('info_panel', ns),
        tagList(
          box(
            title = "Phenotype-Subject Bipartite Network",
            solidHeader = TRUE,          
            width = NULL,
            height = "20%",
            div(class = 'network_header',
                div(class = 'network_controls',
                    checkboxInput(
                      ns("snp_filter"), 
                      label = "Just minor-allele carriers", 
                      value = FALSE
                    )
                ),
                div(class = 'network_controls',
                    span('Copies of minor allele:'),
                    span(class = 'legend_entry', style=paste0("background: ", NO_SNP_COLOR), "0"), 
                    span(class = 'legend_entry', style=paste0("background: ", ONE_SNP_COPY_COLOR), "1"), 
                    span(class = 'legend_entry', style=paste0("background: ", TWO_SNP_COPIES_COLOR), "2") 
                )   
            )
          ),
          tabBox(id = 'network_plot_box',
                 title = "",
                 width = NULL,
                 tabPanel(
                   "2D",
                   div(class = 'networkPlot',
                       meToolkit::network2d_UI(ns('networkPlot'),  height = '100%')
                   )
                 )
          )
        )
        # network_plots_UI('network_plots', ns)
      )
    )
  )
}

main_app <- function(input, output, session, individual_data, results_data, snp_name) {

  #----------------------------------------------------------------
  # Reactive Values based upon user input
  #----------------------------------------------------------------
  app_data <- reactiveValues( 
    included_codes = NULL,
    inverted_codes = c(),
    snp_filter = FALSE,       # start with all individuals regardless of snp status. 
    maf_subset = FALSE        # MAF for patients with current subset of codes. 
  )
  
  # deals with code selection. On startup this is passed null codes and thus selects the top based
  # upon the previous default selection decisions set in the constants file.
  observe({
    app_data$included_codes <- meToolkit::chooseSelectedCodes(
      selection = NULL,             # should get rid of this later. 
      phewas_table = results_data,
      just_snps = !(app_data$snp_filter),
      p_value_threshold = P_VAL_THRESHOLD
    )
  })

  # Take individual level data and subset it to what we want to show.
  observe({

    subseted_to_codes <- individual_data %>% 
      meToolkit::subsetToCodes(
        desired_codes = app_data$included_codes$code,
        codes_to_invert = app_data$inverted_codes
      )
    
    app_data$maf_subset <- mean(subseted_to_codes$snp > 0)
    
    app_data$subset_data <- subseted_to_codes %>%
      filter((snp %in% c(1,2)) | !(app_data$snp_filter)) 

  })

  # reset the inverted codes if the user flips all cases back on.
  observeEvent(app_data$snp_filter, {
    app_data$inverted_codes <- c()
  })

  #----------------------------------------------------------------
  #----------------------------------------------------------------
  # Plots and tables
  #----------------------------------------------------------------
  #----------------------------------------------------------------

  #----------------------------------------------------------------
  # Manhattan Plot and table of Phewas Results
  #----------------------------------------------------------------
  
  observe({
    app_data$included_codes
    manhattan_plot <- callModule(
      phewas_plot_table, 'phewas_plot_table',
      results_data = results_data, 
      included_codes = app_data$included_codes
    )
    
    observeEvent(manhattan_plot(), {
      print('manhattan plot has triggered')
      app_data$included_codes <- manhattan_plot()
    })
  })
  
  # Draw network diagrams
  observe({
    # Generate network data 
    network_data <- app_data$subset_data %>%
      meToolkit::makeNetworkData(
        results_data,
        inverted_codes = app_data$inverted_codes,
        no_copies = NO_SNP_COLOR,
        one_copy = ONE_SNP_COPY_COLOR,
        two_copies = TWO_SNP_COPIES_COLOR
      )
    
    networkPlot <- callModule(meToolkit::network2d, 'networkPlot', network_data, snp_filter=FALSE)

  #   observeEvent(networks(), {
  #     app_data$snp_filter <- networks()
  #   })
  })
  
  # deals with messages from components for filtering the visable codes. 
  observeEvent(input$message, {
    
    message <- input$message
    payload <- unlist(input$message$payload)[-1]
    
    if(message$type == 'invert'){
      app_data$inverted_codes <- meToolkit::invertCodes(payload, app_data$inverted_codes)
    } else {
      app_data$included_codes <- meToolkit::codeFilter(message$type, payload, app_data$included_codes)
    }
  })

  #----------------------------------------------------------------
  # Upset plot of comorbidity patterns
  #----------------------------------------------------------------
  observe({
    req(app_data$subset_data)

    output$upsetPlotV2 <- callModule(meToolkit::upset, 'upsetPlotV2',
                                     codeData = app_data$subset_data %>% mutate(snp = ifelse(snp != 0, 1, 0)),
                                     snpData = individual_data)
    
    # While we're at it, send data to the info boxes
    callModule(meToolkit::infoPanel, 'info_panel', snp_name, individual_data, app_data$maf_subset )
  })
}