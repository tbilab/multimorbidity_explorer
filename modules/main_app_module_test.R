# testing main app module in own shiny app.
source(here::here('helpers/load_libraries.R'))
source(here::here('modules/main_app_module.R'))

cached_data <- read_rds(here('data/preloaded_rs13283456.rds'))

individual_data <- cached_data$individual_data 
# category_colors <- cached_data$category_colors 
phewas_data     <- cached_data$phewas_data 
snp_name        <- cached_data$snp_name 

ui <- shinyUI(
  dashboardPage(
    dashboardHeader(
      title = "Multimorbidity Explorer",
      titleWidth = 300
    ),
    dashboardSidebar(disable = TRUE),
    dashboardBody(
      includeCSS(here("www/custom.css")),
      main_app_UI('main_app')
    ),
    skin = 'black'
  )
)

server <- function(input, output, session) {
  callModule(
    main_app, "main_app",
    individual_data = individual_data,
    results_data = phewas_data,
    snp_name = snp_name
  )
}

shinyApp(ui, server)