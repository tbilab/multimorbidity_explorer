// Info banner for SNP name, MAF for current selection and the entire exome cohort. Along with link to click for genome browser location of SNP.
const exome_color = 'steelblue';
const sel_color = 'orangered';
const maf_chart_start = width/3;
const label_gap= 35;
const point_r = 15;

const {snp, maf_exome, maf_sel} = data;

// draw the snp name in the upper left corner
svg.append('text')
  .text(snp)
  .attr('class', 'snp_name')
  .attr('x', 10)
  .attr('y', 25);
  
// MAF scale
const x = d3.scaleLinear()
  .domain([0,Math.max(maf_exome, maf_sel)*1.1])
  .range([maf_chart_start, width]);
  
  
svg.append('line')
  .attr('class', 'axis_line')
  .attr('x1', maf_chart_start)
  .attr('x2', width)
  .attr('y1', height/2)
  .attr('y2', height/2);

  
const maf_plot = svg.selectAll('#maf_plot')
  .data([
    {group: 'Exome Cohort', maf: maf_exome},
    {group: 'Current Selection', maf: maf_sel}
  ]);
  

// lines from axis to group label
maf_plot.enter().append('line')
  .attr('x1', d => x(d.maf))
  .attr('x2', d => x(d.maf))
  .attr('y1', height/2)
  .attr('y2', d => height/2 + (d.group == 'Exome Cohort' ? -label_gap: label_gap))
  .attr('stroke', 'black')
  .attr('stroke-width', 1);
  
// group label text
maf_plot.enter().append('text')
  .text(d => d.group)
  .attr('class', 'labels')
  .attr('x', d => x(d.maf) - 2)
  .attr('y', d => height/2 + (d.group == 'Exome Cohort' ? -label_gap: label_gap))
  .attr('font-size', 20);

// points on axis for groups
maf_plot.enter().append('circle')
  .attr('cx', d => x(d.maf))
  .attr('cy', height/2)
  .attr('r', point_r)
  .attr('fill', d => d.group == 'Exome Cohort' ? exome_color: sel_color);
  

maf_plot.enter().append('text')
  .text(d => d.maf)
  .attr('class', 'maf_points')
  .attr('x', d => x(d.maf))
  .attr('y', d => height/2)
  .attr('font-size', 15);

  
svg.style('background', 'lightblue');
