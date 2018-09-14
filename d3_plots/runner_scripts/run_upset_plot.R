library(tidyverse)
library(r2d3)
library(here)

setData <- here('data/upset_data/setData.rds') %>% read_rds()
optionsData <- here('data/upset_data/optionsData.rds') %>% read_rds()

setData <- here('data/upset_data/setData_all.rds') %>% read_rds()
optionsData <- here('data/upset_data/optionsData_all.rds') %>% read_rds()

setData %>% 
  r2d3(
    script = here('d3_plots/upset_interactive.js'), 
    css = here('d3_plots/upset.css'),
    dependencies = "d3-jetpack",
    options = list(marginalData = marginalData, overallMaRate = overallMaRate)
  )