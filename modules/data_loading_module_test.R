# testing main app module in own shiny app.
source(here::here('helpers/load_libraries.R'))
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
