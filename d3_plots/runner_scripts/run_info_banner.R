# script to run the info banner r2d3 with simulated data.
source(here::here('helpers/load_libraries.R'))

snp <- 'rs13283456'

results <- meToolkit::getSNPInfo(snp)

results$snp <- snp
results$maf_exome <- 0.02
results$maf_sel <- 0.031

r2d3::r2d3(
  results, 
  script = here('d3_plots/info_banner.js'), 
  dependencies = "d3-jetpack",
  height = '150px',
  width = '700px'
)
