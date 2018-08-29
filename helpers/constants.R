#-----------------------------------------------------------------------------
# Constants for app
#-----------------------------------------------------------------------------
# Maximum number of phenotypes we can display on upset and network plots
MAX_NUM_PHENOS_ALL <- 15
MAX_NUM_PHENOS_SNPS <- 150

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


CATEGORY_COLORS <- c(
  "#895de6",
  "#6ecc3b",
  "#e34bca",
  "#9ad843",
  "#ff3d97",
  "#01d8a6",
  "#ff4254",
  "#64c5ff",
  "#957100",
  "#0074d3",
  "#aad366",
  "#ff8dcc",
  "#4e5b00",
  "#ffb38f",
  "#325c2c",
  "#faba5f",
  "#8b373b",
  "#7e431e" )

ACCEPTED_FORMATS <- c(
  "text/csv",
  "text/comma-separated-values,text/plain",
  ".csv")