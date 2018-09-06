source(here::here('helpers/load_libraries.R'))
source(here::here('modules/data_loading_module.R'))
source(here::here('modules/main_app_module.R'))

ui <- shinyUI(
  dashboardPage(
    dashboardHeader(
      title = "Multimorbidity Explorer",
      titleWidth = 300
    ),
    dashboardSidebar(disable = TRUE),
    dashboardBody(
      includeCSS(here("www/custom.css")),
      shinyjs::useShinyjs(debug = TRUE),
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
      main_app_UI('main_app')
    }
  })
  
  observeEvent(loaded_data(), {
    all_data <- loaded_data()
    app <- callModule(
      main_app, "main_app",
      individual_data = all_data$individual_data,
      results_data = all_data$phewas_data,
      snp_name = all_data$snp_name,
      category_colors = all_data$category_colors
    )
  })
}

shinyApp(ui, server)