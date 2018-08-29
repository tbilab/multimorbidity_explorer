# testing main app module in own shiny app.
library(shiny)
library(shinydashboard)
library(tidyverse)
library(here)
library(magrittr)
library(plotly)
library(r2d3)
library(glue)
library(network3d)

source(here('modules/main_app_module.R'))

cached_data <- read_rds(here('data/preloaded_rs13283456.rds'))

individual_data <- cached_data$individual_data 
category_colors <- cached_data$category_colors 
phewas_data <- cached_data$phewas_data 
snp_name <- cached_data$snp_name 


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
      includeCSS(here("www/custom.css")),
      shinyjs::useShinyjs(debug = TRUE),
      main_app_UI('main_app')
    ),
    skin = 'black'
  )
)

server <- function(input, output, session) {
  set_size_slider <- reactive({input$setSize})
  
  callModule(
    main_app, "main_app",
    individual_data = individual_data,
    results_data = phewas_data,
    snp_name = snp_name,
    category_colors = category_colors, 
    set_size_slider = set_size_slider
  )
}

shinyApp(ui, server)