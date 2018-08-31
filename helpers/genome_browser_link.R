# function to go from a snp id to a genome browser link

make_genome_browser_link <- function(snp, org = 'human', db = 'hg19'){
  glue('http://genome.ucsc.edu/cgi-bin/hgTracks?org={org}&db={db}&position={snp}')
}

snp <- 'rs13283456'
getSNPInfo <- function(snp){
  results <- ncbi_snp_query(snp)
  list(
    chromosome = results$Chromosome,
    ...
  )
}


# install.packages('rsnps')
# library(rsnps)
# annotations(snp = 'rs7903146', output = 'all')
# SNPs <- c("rs332", "rs420358", "rs1837253", "rs1209415715", "rs111068718")
