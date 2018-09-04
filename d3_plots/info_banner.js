// Info banner for SNP name, MAF for current selection and the entire exome cohort. Along with link to click for genome browser location of SNP.
const {snp, maf_exome, maf_sel, gene, chromosome} = data;

const padding = 15;
const exome_color = 'steelblue';
const sel_color = 'orangered';
const maf_chart_start = width/3;
const label_gap= 35;
const point_r = 20;
const selection_height = height/2 - (point_r*1.1);
const exome_height =     height/2 + (point_r*1.1);
const max_freq = Math.max(maf_exome, maf_sel)*1.1;

// turns proportion into a rounded percentange
const toPercent = d3.format(".1%");

// draw the snp name in the upper left corner
svg.append('text')
  .text(snp)
  .attr('class', 'snp_name')
  .attr('x', 10)
  .attr('y', 10);
  
const snp_details = svg.append('g').attr('id', 'snp_details');

snp_details.append('text')
  .html(`Gene: <tspan class = 'snp_info'>${gene}</tspan>`)
  .attr('x', 10)
  .attr('y', height - 50);
  
snp_details.append('text')
  .html(`Chromosome: <tspan class = 'snp_info'>${chromosome}</tspan>`)
  .attr('x', 10)
  .attr('y', height - 30);
  
snp_details.append('text')
  .html(`Genome Browser Link`)
  .attr('class', 'genome_browser_link')
  .attr('x', 10)
  .attr('y', height - 10)
  .on('click', () => {
    
    const db = 'hg19';
    const link = `http://genome.ucsc.edu/cgi-bin/hgTracks?org=human&db=${db}&position=${snp}`;
    
    window.open(link, '_blank');
  });
  
// MAF scale
const x = d3.scaleLinear()
  .domain([0,max_freq])
  .range([maf_chart_start, width - padding]);
  

svg.append("g")
  .attr("transform", `translate(0,${exome_height})`)
  .call( d3.axisBottom(x)
    .tickValues([0, max_freq])
    .tickFormat(toPercent)
    .tickSizeOuter(0)
  );
  
svg.append('line')
  .attr('x1', x(0))
  .attr('x2', x(max_freq))
  .attr('y1', selection_height)
  .attr('y2', selection_height)
  .attr('stroke', 'black')
  .attr('stroke-width', 1);
      
  
const maf_plot = svg.selectAll('#maf_plot')
  .data([ {group: 'Exome Cohort', maf: maf_exome},
          {group: 'Current Selection', maf: maf_sel} ])
  .enter().append('g')
  .attr('transform', d => `translate(${x(d.maf)}, ${d.group == 'Exome Cohort' ? exome_height: selection_height} )`);


// group label text
maf_plot.append('text')
  .text(d => d.group)
  .attr('class', 'labels')
  .attr('alignment-baseline', d => d.group == 'Exome Cohort' ? 'hanging': 'baseline')
  .attr('y',  d => d.group == 'Exome Cohort' ? 2: -3)
  .attr('x', -(point_r + 3));

// points on axis for groups
maf_plot.append('circle')
  .attr('r', point_r)
  .attr('fill', d => d.group == 'Exome Cohort' ? exome_color: sel_color);
  
maf_plot.append('text')
  .text(d => toPercent(d.maf).replace('%',''))
  .attr('class', 'maf_points');
