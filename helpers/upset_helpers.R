# Helper functions for UPSet plot
library(epitools)

calc_RR_CI <- function(pattern_n, pattern_snp, other_n, other_snp, CI_size = 0.95){
  cont_table <- matrix(c(
    pattern_snp, (pattern_n - pattern_snp),
    other_snp, (other_n - other_snp)
  ), nrow = 2, byrow = TRUE
  )
  
  RR_estimates <- riskratio.small(cont_table, rev = "b", conf.level = CI_size)$measure[2,] 

  list(
    PE = RR_estimates[1], 
    lower = RR_estimates[2],
    upper = RR_estimates[3]
  )
}


calc_RR_CI(
  pattern_n=120, pattern_snp=5,
  other_n=2000, other_snp=56,
  CI_size = 0.95
)
#
# $PE
# [1] 1.488095
#
# $lower
# [1] 0.6073917
#
# $upper
# [1] 3.645798
