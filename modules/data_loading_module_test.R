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


# data_0 <- read_rds('data/preloaded_rs13283456.rds')
# data_0
# data <- read_rds('data/preloaded_rs3211783.rds')
# 
# data$phewas_data <- (data$phewas_data) %>%
#   mutate(
#     tooltip = str_replace_all(tooltip, '</br>', '</br>\n')
#   )
# # 
# # # data$category_colors <- data_0$category_colors
# # # data$snp_name = 'rs3211783'
# # # 
# # # data$phewas_data <- data$phewas_data %>% 
# # #   rename(code = phecode) %>% 
# # #   makeTooltips() %>% 
# # #   select(code, category, p_val, tooltip)
# # # 
# data %>% write_rds('data/preloaded_rs3211783.rds', compress = 'gz')
