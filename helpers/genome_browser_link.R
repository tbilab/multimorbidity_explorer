# function to go from a snp id to a genome browser link

make_genome_browser_link <- function(snp, org = 'human', db = 'hg19'){
  glue('http://genome.ucsc.edu/cgi-bin/hgTracks?org={org}&db={db}&position={snp}')
}
