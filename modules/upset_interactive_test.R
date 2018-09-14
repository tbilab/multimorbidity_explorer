# This doesn't work in its current form and needs to be modified to work with the data available in the upset folder within d3 plots.

source(here::here('helpers/load_libraries.R'))
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
      checkboxInput(
        "snp_filter", 
        label = "Just minor-allele carriers", 
        value = FALSE
      ),
      upset2_UI('upsetPlotV2')
    ),
    skin = 'black'
  )
)


server <- function(input, output, session) {
  observe({
    
    
    codeFiltered <- codeData %>% {
      this <- .
      
      if(input$snp_filter) this <- this %>% filter(snp > 0)
      
      this
    }
    
    callModule(upset2, 'upsetPlotV2',
               codeData = codeFiltered,
               snpData = snpData)
  })
  
}

shinyApp(ui, server)

