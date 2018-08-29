# This doesn't work in its current form and needs to be modified to work with the data available in the upset folder within d3 plots.

library(shiny)
library(tidyverse)
library(here)
library(r2d3)

source(here('modules/upset_interactive.R'))

codeData <- here('d3_plots/upset_interactive/upset_data.rds') %>% 
  readr::read_rds()

snp_data <- here('d3_plots/upset_interactive/snp_copies.rds') %>% 
  readr::read_rds()

currentSnp <- 'rs5908'

ui <- fluidPage(
  h1('hi'),
  sliderInput("setSize", "Min Size of Set:",
              min = 0, max = 250,
              value = 20),
  div(
    upset2_UI('upsetPlotV2'),
    style = "height:500px;"
  )
)

server <- function(input, output, session) {
  observe({
    print('set size')
    print(input$setSize)
    callModule(upset2, 'upsetPlotV2', 
               codeData = codeData, 
               snpData = snp_data, 
               currentSnp = currentSnp, 
               minSize = input$setSize
    )  
  })
  
}

shinyApp(ui, server)