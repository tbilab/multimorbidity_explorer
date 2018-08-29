
info_boxes_UI <- function(id, app_ns) {
  ns <- . %>% NS(id)() %>% app_ns()
  
  tagList(
    box(title = "Population Statistics",
        width = NULL,
        solidHeader=TRUE,
        valueBoxOutput(ns("currentSnp")),
        valueBoxOutput(ns("popPercentSnp")),
        valueBoxOutput(ns("numAlleleCarriersCurrent"))
    )
  )
}

info_boxes <- function(input, output, session, snp_name, individual_data, subset_data) {
  
  output$currentSnp <- renderValueBox({
    valueBox(
      snp_name, "Current SNP", icon = icon("id-badge"),
      color = "maroon"
    )
  })
  
  output$popPercentSnp <- renderValueBox({
    snp_perc <- individual_data %>%
      summarise(
        perc_carriers = (sum(snp > 0)/n())*100
      ) %>%
      round(3)
    
    valueBox(
      snp_perc, "MAF in Exome Cohort", icon = icon("percent"),
      color = "olive"
    )
  })

  output$numAlleleCarriersCurrent <- renderValueBox({
    stats <- subset_data %>%
      summarise(
        all = n(),
        carriers = sum(snp > 0)
      )
    
    valueBox(
      paste(stats$carriers, '/', stats$all),
      "MA Carrier to Total # Cases",
      icon = icon("braille"),
      color = "purple"
    )
  }) 
  
}