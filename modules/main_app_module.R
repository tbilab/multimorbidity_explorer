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
        box(
          title = "Upset Plot",
          solidHeader = TRUE,
          width = NULL,
          meToolkit::upset_UI(ns('upsetPlot'), div_class = 'upset_plot')
        )
      ),
      column(
        width = 7,
        meToolkit::infoPanel_UI('info_panel', ns),
        box(
          title = "Phenotype-Subject Bipartite Network",
          solidHeader = TRUE,          
          width = NULL,
          meToolkit::network2d_UI(ns('networkPlot'), 
                                  height = '80%', 
                                  div_class = 'network_plot',
                                  snp_colors = c(NO_SNP_COLOR, ONE_SNP_COPY_COLOR, TWO_SNP_COPIES_COLOR) )
        )
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
  #----------------------------------------------------------------
  # App state that can be modified by user
  #----------------------------------------------------------------  
  app_state <- reactiveValues( 
    # Start with ten most significant phecodes
    selected_codes = results_data %>% arrange(p_val) %>% head(10) %>% pull(code),
    inverted_codes = c(),
    # start with all individuals regardless of snp status
    snp_filter = FALSE       
  )
  
  # Reactive variable that stores the most recent interaction
  app_interaction <- reactiveVal()
  
  #----------------------------------------------------------------
  # App values that change based upon the current state
  #----------------------------------------------------------------  
  # Individual data subset by the currently viewed phecodes and if we've filtered the snp
  curr_ind_data <- reactive({
    meToolkit::subsetToCodes(
      individual_data, 
      desired_codes = app_state$selected_codes,
      codes_to_invert = app_state$inverted_codes
    )
  })
  
  # Network representation of the current data for use in the network plot(s)
  curr_network_data <- reactive({
    meToolkit::makeNetworkData(
      data = curr_ind_data(),
      phecode_info = results_data,
      inverted_codes = app_state$inverted_codes,
      no_copies = NO_SNP_COLOR,
      one_copy = ONE_SNP_COPY_COLOR,
      two_copies = TWO_SNP_COPIES_COLOR
    )
  })
  
  #----------------------------------------------------------------
  # Route all actions through a switch statement to modify the 
  # app's values 
  #---------------------------------------------------------------- 
  observeEvent(app_interaction(),{
    action_type <- app_interaction() %>% pluck('type')
    action_payload <- app_interaction() %>% pluck('payload')
    extract_codes <- . %>% unlist() %>% tail(-1)
    remove_codes <- function(codes, to_remove){
      codes[!(codes %in% to_remove)]
    }
    
    switch(action_type,
           delete = {
             codes_to_delete <- action_payload %>% extract_codes()
             prev_selected_codes <- app_state$selected_codes
             app_state$selected_codes <- remove_codes(prev_selected_codes, codes_to_delete)
             
             print('deleting codes:')
             print(codes_to_delete)
           },
           isolate = {
             print('isolating codes!')
           }, 
           snp_filter_change = {
             print('filtering snp status')
           },
           stop("Unknown input")
    )
  })
  
  #----------------------------------------------------------------
  # Setup all the components of the app
  #---------------------------------------------------------------- 
  
  
  ## Network plot
  network_plot <- callModule(meToolkit::network2d, 'networkPlot', curr_network_data, snp_filter=reactive(app_state$snp_filter))
  
  # Watch network plot for messages and send them to the interaction reactive
  observeEvent(network_plot(),{
    print('the network plot has a message!')
    app_interaction(network_plot())
  })
  
  ## Upset plot
  upset_plot <- callModule(meToolkit::upset, 'upsetPlot', curr_ind_data, select(individual_data, IID, snp))

  
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
  # observe({
  #   req(app_data$subset_data)
  # 
  #   output$upsetPlotV2 <- callModule(meToolkit::upset, 'upsetPlotV2',
  #                                    codeData =individual_data %>% mutate(snp = ifelse(snp != 0, 1, 0)),
  #                                    snpData = individual_data)
  #   
  #   # While we're at it, send data to the info boxes
  #   callModule(meToolkit::infoPanel, 'info_panel', snp_name, individual_data, app_data$maf_subset )
  # })
}