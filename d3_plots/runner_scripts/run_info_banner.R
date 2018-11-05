# script to run the info banner r2d3 with simulated data.
source(here::here('helpers/load_libraries.R'))
source(here::here('helpers/genome_browser_link.R'))

snp <- 'rs13283456'

results <- meToolkit::getSNPInfo(snp)

results$snp <- snp
results$maf_exome <- 0.02
results$maf_sel <- 0.031

r2d3::r2d3(
  results, 
  script = here('d3_plots/info_banner.js'), 
  css = here('d3_plots/info_banner.css'), 
  height = '150px',
  width = '700px'
)
