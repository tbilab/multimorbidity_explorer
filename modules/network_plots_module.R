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
                 meToolkit::network2d_UI(ns('networkPlot'),  height = '100%')
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
  snp_filter
) {
  
  # Make sure the checkbox follows what it should
  updateCheckboxInput(session, "snp_filter", value = snp_filter)
  
  # Generate network data 
  network_data <- subset_data %>%
    meToolkit::makeNetworkData(
      results_data,
      inverted_codes = inverted_codes,
      no_copies = NO_SNP_COLOR,
      one_copy = ONE_SNP_COPY_COLOR,
      two_copies = TWO_SNP_COPIES_COLOR
    )
  
  networkPlot <- callModule(meToolkit::network2d, session$ns('networkPlot'), network_data, snp_filter=snp_filter)

  # return value of user's choice on code filtering
  return(networkPlot)
}