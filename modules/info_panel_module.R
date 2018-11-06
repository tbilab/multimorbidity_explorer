
info_panel_UI <- function(id, app_ns) {
  ns <- . %>% NS(id)() %>% app_ns()
  
  tagList(
    div(
      id = 'info_banner',
      box(title = "",
          width = NULL,
          solidHeader=TRUE,
          r2d3::d3Output(ns("info_banner"), height = '150px')
      )
    )
  )
}

info_panel <- function(input, output, session, snp_name, individual_data, subset_maf) {
  
  snp_info <- meToolkit::getSNPInfo(snp_name)
  snp_info$snp <- snp_name
  snp_info$maf_exome <- mean(individual_data$snp > 0)
  snp_info$maf_sel <- subset_maf
  
  output$info_banner <- r2d3::renderD3({
    r2d3::r2d3(
      snp_info,
      script = here('d3_plots/info_banner.js'),
      css = here('d3_plots/info_banner.css')
    )
  })
}