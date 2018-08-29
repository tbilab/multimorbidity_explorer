# testing main app module in own shiny app.
library(shiny)
library(shinydashboard)
library(magrittr)
library(tidyverse)
library(here)

source(here('helpers/constants.R')) # everything defined here is IN UPPERCASE ONLY
source(here('modules/network_plots_module.R'))

cached_data <- read_rds(here('data/testing/network_module_data.rds'))

subset_data <- cached_data$subset_data
results_data <- cached_data$results_data
inverted_codes <- cached_data$inverted_codes
category_colors <- cached_data$category_colors 
snp_filter <- cached_data$snp_filter


ui <- shinyUI(
  dashboardPage(
    dashboardHeader(
      title = "Multimorbidity Explorer",
      titleWidth = 300
    ),
    dashboardSidebar(
      h2('Settings'),
      sliderInput("setSize", "Min Size of Set:",
                  min = 0, max = 250,
                  value = 20),
      collapsed = TRUE
    ),
    dashboardBody(
      includeCSS(here("www/test_app.css")),
      network_plots_UI('network_plots', I)
    ),
    skin = 'black'
  )
)

server <- function(input, output, session) {
  networks <- callModule(
    network_plots, 'network_plots',
    subset_data = subset_data, 
    results_data = results_data,
    inverted_codes = inverted_codes, 
    category_colors = category_colors,
    parent_ns = session$ns,
    snp_filter = TRUE # THIS NEEDS TO BE WIRED UP PROPERLY 
  )
  
  observeEvent(input$message, {
    print('message from network')
    print(input$message)
  })
}

shinyApp(ui, server)