# install.packages(c('shiny', 'shinydashboard', 'magrittr', 'here', 'glue'))
# devtools::install_github('tbilab/meToolkit', ref = 'exportable_network_plot', force = TRUE)
library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(markdown)
library(glue)
library(meToolkit)
library(shinyjs)

source('modules/data_loading_module.R')
source('modules/main_app_module.R')
  
ui <- shinyUI(
  dashboardPage(
    dashboardHeader(
      title = "Multimorbidity Explorer",
      titleWidth = 300 
    ),
    dashboardSidebar(disable = TRUE),
    dashboardBody( 
      includeCSS("www/custom.css"),
      useShinyjs(debug = TRUE),
      uiOutput("ui")
    ),
    skin = 'black'
  )
)

server <- function(input, output, session) {
  
  loaded_data <- callModule(
    data_loading, "data_loading"
  )
  
  output$ui <- renderUI({
    no_data <- is.null(loaded_data()) 
    if(no_data){
      data_loading_UI('data_loading')
    }else{
      main_app_UI('main_app', unique_codes = unique(loaded_data()$phewas_data$code))
    }
  })
  
  observeEvent(loaded_data(), {
    all_data <- loaded_data()
    app <- callModule(
      main_app, "main_app",
      individual_data = all_data$individual_data,
      results_data = all_data$phewas_data %>% buildColorPalette(category),
      snp_name = all_data$snp_name
    )
  })
}

shinyApp(ui, server)