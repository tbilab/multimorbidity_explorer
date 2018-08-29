# testing main app module in own shiny app.
library(shiny)
library(shinydashboard)
library(tidyverse)
library(here)

source(here('modules/data_loading_module.R'))


ui <- shinyUI(
  data_loading_UI('data_loading')
)


server <- function(input, output, session) {
  loaded_data <- callModule(
    data_loading, "data_loading"
  )
  
  observeEvent(loaded_data(), {
    print(loaded_data())
  })
}

shinyApp(ui, server)