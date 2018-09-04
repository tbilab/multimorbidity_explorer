# script to run the info banner r2d3 with simulated data.

snp <- 'rs13283456'

results <- getSNPInfo(snp)

results$snp <- snp
results$maf_exome <- 0.05
results$maf_sel <- 0.051

r2d3::r2d3(
  results, 
  script = here('d3_plots/info_banner.js'), 
  css = here('d3_plots/info_banner.css'), 
  height = '150px'
)