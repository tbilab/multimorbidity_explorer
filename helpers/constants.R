#-----------------------------------------------------------------------------
# Constants for app
#-----------------------------------------------------------------------------

# P-value threshold for when no codes have been selected.
P_VAL_THRESH <- 0.001

# Color of SNP carriers in upset and network plot
NO_SNP_COLOR <- '#bdbdbd'
ONE_SNP_COPY_COLOR <- '#fcae91'
TWO_SNP_COPIES_COLOR <- '#a50f15'

# debugging helper
DEBUGGING <- TRUE

SNPS_LIST <- c("rs5908", "rs200445019", "rs35480887")

# Which snp do we start out with?
STARTING_SNP <- 'rs200445019'


ACCEPTED_FORMATS <- c(
  "text/csv",
  "text/comma-separated-values,text/plain",
  ".csv")