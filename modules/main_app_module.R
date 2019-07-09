# Color of SNP carriers in upset and network plot
NO_SNP_COLOR <- '#bdbdbd'
ONE_SNP_COPY_COLOR <- '#fcae91'
TWO_SNP_COPIES_COLOR <- '#a50f15'

main_app_UI <- function(id, unique_codes) {
  ns <- NS(id)
  tagList(
    tags$head( tags$link(rel = "stylesheet", type = "text/css", href = "custom.css") ),
    fluidRow(
      column(
        width = 5,
        box(title = "Manhattan Plot (Phecode 1.2)",
            width = NULL,
            solidHeader=TRUE,          
            collapsible = TRUE,
            div(id = 'manhattanPlot',
               manhattan_plot_UI(ns('manhattan_plot'))
            )
        ),
        div(id = 'selected_code_box',
            box(
              title = "Phewas Results (Selected Codes)",
              id = 'codeTable',
              solidHeader=TRUE,          
              width = NULL,
              collapsible = TRUE,
              collapsed = TRUE,
              phewas_table_UI(ns('phewas_table')),
              hr(),
              selectizeInput(
                ns("desired_codes"), 
                "Custom select desired PheCodes (type to find)", 
                choices = unique_codes,
                multiple = TRUE ),
              actionButton(
                ns("filter_to_desired"),
                'Filter to desired'
              )
            )
        ),
        box(
          title = "Upset Plot",
          solidHeader = TRUE,
          width = NULL,
          upset_UI(ns('upsetPlot'), div_class = 'upset_plot')
        )
      ),
      column(
        width = 7,
        div(style = "margin-top: 10px;",
          box(
            solidHeader = TRUE,
            width = NULL,
            info_panel_UI(ns('info_panel'))
          )
        ),
        box(
          title = "Phenotype-Subject Bipartite Network",
          solidHeader = TRUE,          
          width = NULL,
          network_plot_UI(ns('network_plot'), 
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
  # App state that can be modified by user. 
  #   This explicitely defines what the user can interact with. 
  #   Each snapshot of this state fully defines the current view of the app. 
  #----------------------------------------------------------------  
  state <- list(
    # Start with top 5 codes selected
    selected_codes = reactiveVal(results_data %>% arrange(p_val) %>% head(5) %>% pull(code)),
    # Start with all codes not inverted
    inverted_codes = reactiveVal(c()),
    # Start with all individuals regardless of snp status
    snp_filter = reactiveVal(FALSE),
    # Pattern to highlight in network plot,
    highlighted_pattern = reactiveVal(c())
  )
 
  #----------------------------------------------------------------
  # App values that change based upon the current state
  #----------------------------------------------------------------  
  # Individual data subset by the currently viewed phecodes and if we've filtered the snp
  curr_ind_data <- reactive({
    
    keep_everyone <- !(state$snp_filter())
    # Filter the individual data to just MA carriers if needed, otw keep everyone
    
    individual_data %>% 
      filter((snp > 0) | keep_everyone) %>%  
      subsetToCodes(
        desired_codes = state$selected_codes(),
        codes_to_invert = state$inverted_codes()
      )
  })
  
  # Network representation of the current data for use in the network plot(s)
  curr_network_data <- reactive({
    makeNetworkData(
      data = curr_ind_data(),
      phecode_info = results_data,
      inverted_codes = state$inverted_codes(),
      no_copies = NO_SNP_COLOR,
      one_copy = ONE_SNP_COPY_COLOR,
      two_copies = TWO_SNP_COPIES_COLOR
    )
  })
  
  #----------------------------------------------------------------
  # Route all actions through a switch statement to modify the 
  # app's values 
  #---------------------------------------------------------------- 
  # Reactive variable that stores the most recent interaction
  app_interaction <- reactiveVal()
  
  observeEvent(app_interaction(),{
    action_type <- app_interaction() %>% pluck('type')
    action_payload <- app_interaction() %>% pluck('payload')
    extract_codes <- . %>% unlist() %>% tail(-1)
    remove_codes <- function(codes, to_remove){
      codes[!(codes %in% to_remove)]
    }
    
    print(glue("Action of type {action_type} received"))
    action_type %>% 
      switch(
        delete = {
          codes_to_delete <- action_payload %>% extract_codes()
          prev_selected_codes <- state$selected_codes()
          state$selected_codes(remove_codes(prev_selected_codes, codes_to_delete)) 
          
          print('deleting codes:')
          print(codes_to_delete)
        },
        selection = {
          print('selecting codes!')
          if(length(action_payload) < 2){
            warnAboutSelection()
          } else {
            state$selected_codes(action_payload)
          }
        },
        isolate = {
          print('isolating codes!')
          desired_codes <- extract_codes(action_payload)
          if(length(desired_codes) < 2){
            warnAboutSelection()
          } else {
            state$selected_codes(desired_codes) 
          }
        }, 
        snp_filter_change = {
          print('filtering snp status')
          state$snp_filter(!state$snp_filter())
          print(glue('New snp filter status is {state$snp_filter()}'))
        },
        pattern_highlight = {
          # print('Upset sent a pattern higlight request')
          # print(extract_codes(action_payload))
          # state$highlighted_pattern(extract_codes(action_payload))
        },
        stop("Unknown input")
    )
  })
  
  #----------------------------------------------------------------
  # Setup all the components of the app
  #---------------------------------------------------------------- 
  ## Network plot
  callModule(
    network_plot, 'network_plot',
    curr_network_data,
    state$highlighted_pattern,
    snp_filter = state$snp_filter,
    viz_type = 'free',
    update_freq = 25,
    action_object = app_interaction
  )

  ## Upset plot
  upset_plot <- callModule(
    upset, 'upsetPlot', 
    curr_ind_data, 
    select(individual_data, IID, snp),
    app_interaction
  )

  ## Manhattan plot
  manhattan_plot <- callModule(
    manhattan_plot, 'manhattan_plot',
    results_data = results_data,
    selected_codes = state$selected_codes,
    action_object = app_interaction
  )
  
  ## PheWAS table 
  callModule(
    phewas_table, 'phewas_table',
    results_data = results_data,
    selected_codes = state$selected_codes,
    action_object = app_interaction
  )
  
  ## Multicode selecter input
  observeEvent(input$filter_to_desired, {
    codes_desired <- input$desired_codes
    action_object_message <-  list(
      type = 'selection',
      payload = codes_desired
    )
    
    app_interaction(action_object_message)
  })

  ## SNP info panel
  callModule(
    info_panel, 'info_panel', 
    snp_name, 
    individual_data, 
    curr_ind_data 
  )

}
