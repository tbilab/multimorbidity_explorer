# Inputs: 
# 

# Outputs: 
# Reactive function that emits a list of codes that have been either selected or deleted or inverted. 

source(here::here('helpers/network_helpers.R'))
network_plots_UI <- function(id, app_ns) {
  ns <- . %>% NS(id)() %>% app_ns()
  
  tagList(
    box(
      title = "Phenotype-Subject Bipartite Network",
      solidHeader=TRUE,          
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
                 r2d3::d3Output(ns("networkPlot2d"), height = '100%')
             )
           ),
           tabPanel(
             "3D", 
             div(class = 'networkPlot',
                 network3d::network3dOutput(ns("networkPlot"), height = '100%')
             )
           )
    )
  )
}

network_plots <- function(
  input, output, session, 
  subset_data, 
  results_data,
  inverted_codes, 
  category_colors,
  snp_filter,
  parent_ns
) {
  
  # Make sure the checkbox follows what it should
  updateCheckboxInput(session, "snp_filter", value = snp_filter)
  
  # Generate network data to be used in both 2d and 3d plots
  network_data <- subset_data %>%
    meToolkit::makeNetworkData(
      results_data,
      inverted_codes = inverted_codes,
      category_colors$palette,
      no_copies = NO_SNP_COLOR,
      one_copy = ONE_SNP_COPY_COLOR,
      two_copies = TWO_SNP_COPIES_COLOR
    )
  
  write_rds(network_data, here('data/testing_network_data_snp_filter.rds'))
  
  # browser()
  
  # send data and options to the 2d plot
  output$networkPlot2d <- r2d3::renderD3({
    network_data %>%
      jsonlite::toJSON() %>%
      r2d3::r2d3(
        script = here('d3_plots/network_2d.js'),
        container = 'canvas',
        dependencies = "d3-jetpack",
        options = list(
            just_snp = snp_filter, 
            msg_loc = parent_ns('message')
          )
      )
  })
  
  # send data and options to the 3d plot
  output$networkPlot <- network3d::renderNetwork3d({
    network_data %$%
      network3d::network3d(
        force_explorer = FALSE,
        html_tooltip = TRUE,
        vertices,
        edges,
        manybody_strength = -1.9,
        max_iterations = 120,
        edge_opacity = 0.2
      )
  })
  
  # return value of user's choice on the snp filtering. 
  return(
    reactive({
      return(input$snp_filter)
    })
  )
}