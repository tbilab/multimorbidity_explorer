# Helper functions for UPSet plot

# Calculate the relative risk point estimate and exact confidence interval using loged normal approximation
calc_RR_CI <- function(pattern_n, pattern_snp, other_n, other_snp, CI_size = 0.95){
  pattern_prob <- pattern_snp/pattern_n
  other_prob <- other_snp/other_n
  
  # relative to the non-pattern values this is the 'risk' of having a copy of the MA.
  RR <- pattern_prob / other_prob
  
  internal_frac <- function(snp, n){
    ((n-snp)/snp)/n
  }
  
  width_scalar <- sqrt(internal_frac(pattern_snp, pattern_n) + internal_frac(other_snp, other_n))
  
  # normal Z score for CI width
  Z <- -qnorm((1-CI_size)/2)
  
  lower_bound <- exp(log(RR) - (Z*width_scalar))
  upper_bound <- exp(log(RR) + (Z*width_scalar))
  
  list(
    PE = RR, 
    lower = lower_bound,
    upper = upper_bound
  )
}
# calc_RR_CI(
#   pattern_n=120, pattern_snp=5, 
#   other_n=2000, other_snp=56, 
#   CI_size = 0.95
# )
# # 
# # $PE
# # [1] 1.488095
# # 
# # $lower
# # [1] 0.6073917
# # 
# # $upper
# # [1] 3.645798
