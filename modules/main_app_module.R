source(here('helpers/constants.R')) # everything defined here is IN UPPERCASE ONLY
source(here('helpers/helpers.R'))
source(here('helpers/code_filtering.R'))
source(here('modules/upset_interactive.R'))
source(here('modules/info_boxes_module.R'))
source(here('modules/network_plots_module.R'))
source(here('modules/phewas_plot_table_module.R'))


main_app_UI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head( tags$link(rel = "stylesheet", type = "text/css", href = "custom.css") ),
    fluidRow(column(
      width = 5,
      phewas_plot_table_UI('phewas_plot_table', ns),
      box(
        title = "Comorbidity Patterns",
        width = NULL,
        solidHeader=TRUE,          
        collapsible = TRUE,
        div(id = 'upset2',
            upset2_UI(ns('upsetPlotV2'))
        )
      )
    ),
    column(
      width = 7,
      info_boxes_UI('info_boxes', ns),
      network_plots_UI('network_plots', ns)
    ))
  )
}

main_app <- function(input, output, session, individual_data, results_data, snp_name, category_colors, set_size_slider) {

  #----------------------------------------------------------------
  # Reactive Values based upon user input
  #----------------------------------------------------------------
  app_data <- reactiveValues( 
    included_codes = NULL,
    inverted_codes = c(),
    snp_filter = FALSE          # start with all individuals regardless of snp status. 
  )
  
  # deals with code selection. On startup this is passed null codes and thus selects the top based
  # upon the previous default selection decisions set in the constants file.
  observe({
    app_data$included_codes <- getSelectedCodes(
      selection = NULL,             # should get rid of this later. 
      phewas_table = results_data,
      just_snps = !(app_data$snp_filter)
    )
  })

  # Take individual level data and subset it to what we want to show.
  observe({
    app_data$subset_data <- individual_data %>%
      filter((snp %in% c(1,2)) | !(app_data$snp_filter)) %>%
      subsetToCodes(
        desiredCodes = app_data$included_codes$code,
        codes_to_invert = app_data$inverted_codes
      )
  })

  # reset the inverted codes if the user flips all cases back on.
  observeEvent(app_data$snp_filter, {
    print('observed the snp filter input. ')
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
      included_codes = app_data$included_codes,
      category_colors = category_colors
    )
    
    observeEvent(manhattan_plot(), {
      print('code filtering from the manhattan plot and table!')
      app_data$included_codes <- manhattan_plot()
    })
  })
  
  # Draw network diagrams
  observe({
    networks <- callModule(
      network_plots, 'network_plots',
      subset_data = app_data$subset_data, 
      results_data = results_data,
      inverted_codes = app_data$inverted_codes, 
      category_colors = category_colors,
      snp_filter = app_data$snp_filter, # THIS NEEDS TO BE WIRED UP PROPERLY 
      parent_ns = session$ns 
    )
    
    observeEvent(networks(), {
      app_data$snp_filter <- networks()
    })
  })
  
  # deals with messages from components for filtering the visable codes. 
  observeEvent(input$message, {
    message <- input$message
    payload <- unlist(input$message$payload)[-1]
    
    if(message$type == 'invert'){
      app_data$inverted_codes <- invertCodes(payload, app_data$inverted_codes)
    } else {
      app_data$included_codes <- codeFilter(message$type, payload, app_data$included_codes)
    }
  })

  #----------------------------------------------------------------
  # Upset plot of comorbidity patterns
  #----------------------------------------------------------------
  observe({
    req(app_data$subset_data, set_size_slider())
    setSize <- set_size_slider()

    if(app_data$snp_filter){
      minSize <- 1
    } else {
      minSize <- setSize
    }

    codeData <- app_data$subset_data %>%
      mutate(snp = ifelse(snp != 0, 1, 0))

    output$upsetPlotV2 <- callModule(upset2, 'upsetPlotV2',
                                     codeData = codeData,
                                     snpData = individual_data,
                                     minSize = minSize )
    
    # While we're at it, send data to the info boxes
    callModule(info_boxes, 'info_boxes', snp_name, individual_data, app_data$subset_data)
  })
}