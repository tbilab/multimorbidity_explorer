source(here('helpers/upset_helpers.R'))

upset2_UI <- function(id, app_ns = I) {
  ns <- . %>% NS(id)() %>% app_ns()
  
  tagList(
    boxPlus(
      title = "Multimorbidity Patterns",
      width = NULL,
      id = 1,
      collapsible = TRUE, 
      closable = FALSE,
      solidHeader=TRUE,
      enable_dropdown = TRUE,
      dropdown_icon = "wrench",
      dropdown_menu = dropdownItemList(
        sliderInput(ns("setSize"), "Min Size of Set:",
                    min = 0, max = 250,
                    value = 20)
      ),
      div(id = 'upset2',
          d3Output(ns('chart'), height = '100%')
      )
    )
  )
}

upset2 <- function(input, output, session, codeData, snpData, currentSnp) {
  # In order to get our general enrichment we will need all people in the dataset's snp data. 
  snpAllCases <- snpData %>% 
    select(IID, copies = snp)
  
  rawData <- codeData %>% 
    tidyr::gather(code, value, -IID, -snp) %>% 
    filter(value != 0)
  
  caseLevelPatterns <- rawData %>% 
    group_by(IID) %>% 
    summarise(
      pattern = paste(code, collapse = '-'),
      size = n(), 
      snp = last(snp)
    )
  
  
  testEnrichment <- function(currentPattern){
    caseLevelPatterns %>% 
      right_join(snpAllCases, by = 'IID') %>% 
      mutate(hasPattern = case_when(
        pattern == currentPattern ~ 'yes',
        TRUE ~ 'no'
      )
      ) %>% 
      group_by(hasPattern) %>% 
      summarise(
        MaCarriers = sum(copies != 0),
        Total = n(),
        PropMa = MaCarriers/Total
      ) %>% {

        RR_results <- calc_RR_CI(.$Total[2], .$MaCarriers[2], .$Total[1], .$MaCarriers[1])
        
        data_frame(
          pointEst = RR_results$PE,
          lower = RR_results$lower,
          upper = RR_results$upper
        )
      } 
  }
  
  overallMaRate <- mean(snpAllCases$copies != 0)
  
  allSets <- caseLevelPatterns %>% 
    group_by(pattern) %>% 
    summarise(
      count = n(), 
      size = last(size),
      num_snp = sum(snp)
    )
  
  
  output$chart <- renderD3({

    setData <- allSets %>% 
      filter(count > input$setSize) %>% 
      arrange(size, desc(count)) %>% 
      bind_cols(map_df(.$pattern, testEnrichment))
    
    codesLeft <- setData$pattern %>% 
      paste(collapse = '-') %>% 
      str_split('-') %>% 
      `[[`(1) %>% 
      unique()
    
    marginalData <- rawData %>% 
      filter(code %in% codesLeft) %>% 
      group_by(code) %>% 
      summarise(
        count = n(),
        num_snp = sum(snp)
      ) %>% 
      jsonlite::toJSON()
    
    # Writes files for live development. 
    write_rds(setData, here('data/upset_data/setData_all.rds'))
    write_rds(list(marginalData = marginalData, overallMaRate = overallMaRate), here('data/upset_data/optionsData_all.rds'))
    
    setData %>% 
      r2d3(
        script = here('d3_plots/upset_interactive.js'), 
        css = here('d3_plots/upset.css'),
        dependencies = "d3-jetpack",
        options = list(marginalData = marginalData, overallMaRate = overallMaRate)
      )
    
  })
}