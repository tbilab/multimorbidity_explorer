# function to go from a snp id to a genome browser link

make_genome_browser_link <- function(snp, org = 'human', db = 'hg19'){
  glue('http://genome.ucsc.edu/cgi-bin/hgTracks?org={org}&db={db}&position={snp}')
}

# snp <- 'rs13283456'
getSNPInfo <- function(snp){
  results <- ncbi_snp_query(snp)
  list(
    chromosome = results$Chromosome,
    gene = results$Gene, 
    major_allele = results$Major,
    minor_allele = results$Minor,
    MAF = results$MAF,
    loc = results$BP
  )
}
