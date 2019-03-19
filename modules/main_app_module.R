source(here('helpers/constants.R')) # everything defined here is IN UPPERCASE ONLY

main_app_UI <- function(id) {
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
               meToolkit::manhattan_plot_UI(ns('manhattan_plot'))
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
              meToolkit::phewas_table_UI(ns('phewas_table'))
            )
        ),
        box(
          title = "Upset Plot",
          solidHeader = TRUE,
          width = NULL,
          meToolkit::upset_UI(ns('upsetPlot'), div_class = 'upset_plot')
        )
      ),
      column(
        width = 7,
        div(style = "margin-top: 10px;",
          box(
            solidHeader = TRUE,
            width = NULL,
            meToolkit::info_panel_UI(ns('info_panel'))
          )
        ),
        box(
          title = "Phenotype-Subject Bipartite Network",
          solidHeader = TRUE,          
          width = NULL,
          meToolkit::network_plot_UI(ns('network_plot'), 
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
  # App state that can be modified by user. All state variables are prefixed with state_*
  #----------------------------------------------------------------  
  # Start with ten most significant phecodes
  state_selected_codes <- reactiveVal(results_data %>% arrange(p_val) %>% head(10) %>% pull(code))
  
  # Start with all codes not inverted
  state_inverted_codes <- reactiveVal(c())
  
  # start with all individuals regardless of snp status
  state_snp_filter <- reactiveVal(FALSE)
  
  #----------------------------------------------------------------
  # App values that change based upon the current state
  #----------------------------------------------------------------  
  # Individual data subset by the currently viewed phecodes and if we've filtered the snp
  curr_ind_data <- reactive({
    meToolkit::subsetToCodes(
      individual_data, 
      desired_codes = state_selected_codes(),
      codes_to_invert = state_inverted_codes()
    )
  })
  
  # Network representation of the current data for use in the network plot(s)
  curr_network_data <- reactive({
    meToolkit::makeNetworkData(
      data = curr_ind_data(),
      phecode_info = results_data,
      inverted_codes = state_inverted_codes(),
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
    
    action_type %>% 
      switch(
        delete = {
          codes_to_delete <- action_payload %>% extract_codes()
          prev_selected_codes <- state_selected_codes()
          state_selected_codes(remove_codes(prev_selected_codes, codes_to_delete)) 
          
          print('deleting codes:')
          print(codes_to_delete)
        },
        selection = {
          print('selecting codes!')
          state_selected_codes(action_payload)
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
  callModule(
    meToolkit::network_plot,
    'network_plot',
    curr_network_data,
    snp_filter = state_snp_filter,
    viz_type = 'free',
    update_freq = 10,
    action_object = app_interaction
  )

  ## Upset plot
  upset_plot <- callModule(
    meToolkit::upset, 'upsetPlot', 
    curr_ind_data, 
    select(individual_data, IID, snp)
  )

  ## Manhattan plot
  manhattan_plot <- callModule(
    meToolkit::manhattan_plot, 'manhattan_plot',
    results_data = results_data,
    selected_codes = state_selected_codes,
    action_object = app_interaction
  )
  
  ## PheWAS table 
  callModule(
    meToolkit::phewas_table, 'phewas_table',
    results_data = results_data,
    selected_codes = state_selected_codes,
    action_object = app_interaction
  )
  
  ## SNP info panel
  callModule(
    meToolkit::info_panel, 'info_panel', 
    snp_name, 
    individual_data, 
    curr_ind_data 
  )

}
