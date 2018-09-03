source(here::here('helpers/load_libraries.R'))
source(here('modules/info_boxes_module.R'))

cached_data <- read_rds(here('data/infoboxes_data.rds'))

snp_name <- cached_data$snp_name
individual_data <- cached_data$individual_data
subset_data <- cached_data$subset_data


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
      info_boxes_UI('info_boxes', I)
    ),
    skin = 'black'
  )
)

server <- function(input, output, session) {
  callModule(info_boxes, 'info_boxes', snp_name, individual_data, subset_data)
}

shinyApp(ui, server)