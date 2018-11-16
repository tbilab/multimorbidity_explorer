source(here::here('helpers/load_libraries.R'))
# source(here('modules/info_panel_module.R'))

cached_data <- read_rds(here('data/infoboxes_data.rds'))

snp_name <- cached_data$snp_name
individual_data <- cached_data$individual_data
subset_maf <- 0.4


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
      meToolkit::infoPanel_UI('info_panel', I)
    ),
    skin = 'black'
  )
)

server <- function(input, output, session) {
  callModule(meToolkit::infoPanel, 'info_panel', snp_name, individual_data, subset_maf)
}

shinyApp(ui, server)