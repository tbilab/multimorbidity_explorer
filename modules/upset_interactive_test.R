# This doesn't work in its current form and needs to be modified to work with the data available in the upset folder within d3 plots.

library(shiny)
library(tidyverse)
library(here)
library(r2d3)

source(here('modules/upset_interactive.R'))

upsetData <- here('data/upset_data.rds') %>% 
  readr::read_rds()

codeData <- upsetData$codeData
snpData <- upsetData$snpData

currentSnp <- 'rs5908'


ui <- shinyUI(
  dashboardPage(
    dashboardHeader(
      title = "Multimorbidity Explorer",
      titleWidth = 300
    ),
    dashboardSidebar(disable = TRUE),
    dashboardBody(
      includeCSS(here("www/custom.css")),
      upset2_UI('upsetPlotV2')
    ),
    skin = 'black'
  )
)


server <- function(input, output, session) {
  observe({
    callModule(upset2, 'upsetPlotV2',
               codeData = codeData,
               snpData = snpData)
  })
  
}

shinyApp(ui, server)

