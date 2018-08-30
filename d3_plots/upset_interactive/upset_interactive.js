// !preview r2d3 data=setData, options = optionsList, dependencies = "d3-jetpack", css='upset_interactive/upset.css'
// r2d3: https://rstudio.github.io/r2d3
//

// number formatters
const countFormat = d3.format(",d");
const CiFormat = d3.format(".3f");
const pValFormat = d3.format("0.2");

// Hardcoded settings
const highlightColor = '#fdcdac'; // Color of the highlight bars
const margin = {right: 20, left: 10, top: 20, bottom: 50}; // margins on side of chart

// layout grid
const proportionPlotUnits = 3; // width of proportion CIs
const matrixPlotUnits = 2;
const countBarUnits = 3;
const marginalChartRatio = 1/3;  // what proportion of vertical space is the code marginal count bars?

// matrix settings
const matrixPadding = 5;              // How far in from sides the dots start
const matrixSize = 7;                  // radius of dots
const matrixPresentColor = 'black'; 
const matrixMissingColor = 'lightgrey';

// proportion plot settings
const propPointSize = 3; // size of the point estimates for proportions
const ciThickness = 4;   // how thick is the CI?

// maginal bars settings
const marginalBottomPadding = 5;  // padding between matrix and start of bars
const marginalBarPadding = 0.5;

// count bar settings
const countBarPadding = 0.5;  // vertical gap between count bars.
const countBarLeftPad = 35; // how much space on left of count bars do we leave for popup info?


// Calculated constants
const h = height - margin.top - margin.bottom;
const w = width - margin.left - margin.right;
const totalWidthUnits = proportionPlotUnits + matrixPlotUnits + countBarUnits;
const proportionPlotWidth = w*(proportionPlotUnits/totalWidthUnits);
const matrixPlotWidth = w*(matrixPlotUnits/totalWidthUnits);
const countBarWidth = w*(countBarUnits/totalWidthUnits);
const marginalChartHeight = h*marginalChartRatio;
const matrixDotSize = Math.min(
  (matrixPlotWidth )/(data.length), 
  matrixSize
);

 

// empty old svg content
svg.html('');

// Parent padded g element.
const padded = svg.append('g')
  .translate([margin.left, margin.top]);

// get unique codes present in the data.
const codeList = Object.keys(
  data
  .reduce(
    (all, current) => [...all, ...(current.pattern.split('-'))],
    []
  ).reduce(
    (codeDict, currentCode) => Object.assign(codeDict, {[currentCode]: 1}),
    {}
  )
);


// ----------------------------------------------------------------------
// Scales
// ----------------------------------------------------------------------
const matrixWidthScale = d3.scaleBand()
  .domain(codeList)
  .range([matrixPadding,matrixPlotWidth - matrixPadding])
  .round(true)
  .padding(0.05); // goes from right to left into left margin.
  
const horizontalSpace = matrixWidthScale.bandwidth();

const marginBarWidth = horizontalSpace - 2*marginalBarPadding;

const countX = d3.scaleLinear()
  .range([countBarWidth, countBarLeftPad])
  .domain([0, d3.max(data, d=> d.count)]);

const proportionX = d3.scaleLinear()
  .range([0,proportionPlotWidth])
  .domain([0,d3.max(data, d => d.upperOr)]);
  
const y = d3.scaleLinear()
  .range([marginalChartHeight, h])
  .domain([0, data.length]);

const verticalSpace = y(1) - y(0);   // how big of a gap each pattern gets
const barHeight = verticalSpace - 2*countBarPadding;

const marginalY = d3.scaleLinear()
  .range([marginalChartHeight-marginalBottomPadding, 0])
  .domain([0, d3.max(options.marginalData, d => d.count)]);

// ----------------------------------------------------------------------
// Chart Components
// ----------------------------------------------------------------------

const matrixChart = padded.append('g.matrixChart')
  .translate([proportionPlotWidth,0]);
  
matrixChart.selectAll('.currentRow')
  .data(data)
  .enter().append('g.currentRow')
  .translate((d,i) => [0, y(i)] )
  .each(function(currentEntry, i){
    
    // Initially hidden box for highlighting purposes. 
    const highlightRect = d3.select(this)
      .selectAppend('rect.highlightRect')
      .at({
        width: w + 20,
        x: -(countBarWidth + countBarPadding*2),
        height: barHeight + countBarPadding,
        fillOpacity: 0.3,
        fill: highlightColor,
        stroke: 'black',
        rx: 5,
        opacity: 0,
        'class': 'hoverInfo'
      });
    
    // Matrix key
    const matrixRow = d3.select(this).append('g.matrixRow');

    const allCodes = matrixRow
      .selectAll('.allCodes')
      .data(codeList)
      .enter().append('circle')
      .attr('class', 'allCodes')
      .at({
        cx: d => matrixWidthScale(d) + matrixWidthScale.bandwidth()/2, 
        cy: verticalSpace/2,
        r: matrixDotSize, 
        fill: matrixMissingColor,
        fillOpacity: 0.3,
      });
    
    // bars that go accross
    const codePositions = currentEntry.pattern
      .split('-')
      .map(d => matrixWidthScale(d) + matrixWidthScale.bandwidth()/2);
    
    const rangeOfPattern = d3.extent(codePositions)

    matrixRow.append('line')
      .at({
        x1: rangeOfPattern[0],
        x2: rangeOfPattern[1],
        y1: verticalSpace/2,
        y2: verticalSpace/2,
        stroke: matrixPresentColor,
        strokeWidth: matrixDotSize/2
      })
    
    const presentCodes = matrixRow
      .selectAll('.presentCodes')
      .data(codePositions)
      .enter().append('circle')
      .attr('class', 'presentCodes')
      .at({
        cx: d => d, 
        cy: verticalSpace/2,
        r: matrixDotSize, 
        fill: matrixPresentColor,
      });
      
      
    // Proportion Intervals
    const proportionBar = d3.select(this).append('g.proportionBar')
      .translate([matrixPlotWidth, 0]);
      
    const intervalBar = proportionBar
      .append('line')
      .at({
        x1: proportionX(currentEntry.lowerOr),
        x2: proportionX(currentEntry.upperOr),
        y1: verticalSpace/2, y2: verticalSpace/2,
        stroke: currentEntry.pointEst === 0 ? 'darkgrey': 'orangered',
        strokeWidth: ciThickness,
      });
      
    const pointEst = proportionBar
      .append('circle')
      .at({
        cx: proportionX(currentEntry.pointEst),
        cy: verticalSpace/2,
        r: propPointSize,
        fill:currentEntry.pointEst === 0 ? 'darkgrey': 'orangered',
        stroke: 'black',
        strokeWidth: 0.5,
      });
 
    proportionBar
      .append('text')
      .html(d => `<tspan>CI:</tspan> (${CiFormat(currentEntry.lowerOr)},${CiFormat(currentEntry.upperOr)})`)
      .at({
        x: 50,
        y: -y(i) + marginalChartHeight/3.5,
        opacity: 0,
        fontSize: 22,
        textAnchor: 'start',
        'class': 'hoverInfo'
      });
      
    proportionBar
      .append('text')
      .html(d => `<tspan>P-Value:</tspan> ${pValFormat(currentEntry.pVal)}`)
      .at({
        x: 50,
        y: -y(i) + marginalChartHeight/2,
        opacity: 0,
        fontSize: 22,
        textAnchor: 'start',
        'class': 'hoverInfo'
      });
      
    // Count Bars
    const countBar = d3.select(this).append('g.countBar')
      .translate([-countBarWidth,0]);
    
    countBar.append('rect')
      .at({
        fill: 'steelblue',
        height: barHeight,
        x: countX(currentEntry.count),
        y: countBarPadding/2,
        width: countX(0) - countX(currentEntry.count),
      })
    
    countBar.append('text')
      .text(countFormat(currentEntry.count))
      .at({
        x: countX(currentEntry.count) - 1,
        y: -y(i) + marginalChartHeight - 28,
        alignmentBaseline: 'middle',
        textAnchor: 'end',
        fontWeight: 'bold',
        opacity: 0,
        'class': 'hoverInfo'
      })
      
     countBar.append('line')
      .at({
        x1: countX(currentEntry.count),
        x2: countX(currentEntry.count),
        y1: -y(i) + marginalChartHeight - 28,
        y2: -y(i) + marginalChartHeight,
        stroke: 'black',
        opacity: 0,
        'class': 'hoverInfo'
      })
  })
  .on('mouseover', function(d){
    d3.select(this).selectAll('.hoverInfo').attr('opacity', 1)
  })
  .on('mouseout', function(d){
    d3.select(this).selectAll('.hoverInfo').attr('opacity', 0)
  })
// ----------------------------------------------------------------------
// Axes
// ----------------------------------------------------------------------

const matrixAxis = matrixChart.append("g")
  .call(d3.axisBottom().scale(matrixWidthScale))
  .translate([0, h]);

matrixAxis
  .selectAll("text")
  .at({
    x: -7,
    y: -1,
    textAnchor: 'end',
    transform: 'rotate(-60)',
    fontSize:12
  });
    
matrixAxis.select('.domain').remove()

const proportionAxis = padded.append('g.proportionAxis')
  .translate([matrixPlotWidth + countBarWidth, marginalChartHeight - marginalBottomPadding])

proportionAxis.append("g")
  .call(d3.axisTop().scale(proportionX).ticks(5))
  .selectAll("text")
  .at({
    textAnchor: 'start',
    x: 2,
    y: -5,
    opacity: 0.5,
  });

proportionAxis.select('.tick').select('line')
  .at({
    y1: h-marginalChartHeight
  });
  
proportionAxis.append('text')
  .at({
    x: proportionPlotWidth/2,
    y: h - marginalChartHeight+ 20,
  })
  .classed('axisTitles', true)
  .text('MA Proportion')

// Add a line to show overall snp proportions
proportionAxis.append('line')
  .at({
    x1: proportionX(options.overallMaRate),
    x2: proportionX(options.overallMaRate), 
    y1: 0,
    y2: h - marginalChartHeight,
    stroke: 'black',
    opacity: 0.2,
  })

proportionAxis.append('line')
  .at({
    x1: proportionX(options.overallMaRate) + 10,
    x2: proportionX(options.overallMaRate), 
    y1: h - marginalChartHeight + 20,
    y2: h - marginalChartHeight,
    stroke: 'black',
    opacity: 0.2,
  })
  
proportionAxis.append('text')
  .text(`Overall Proportion: ${CiFormat(options.overallMaRate)}`)
  .at({
    x: proportionX(options.overallMaRate) + 11,
    y: h - marginalChartHeight + 25,
    textAnchor: 'start',        
    alignmentBaseline: 'hanging',
    fontSize: 14,
    fill: 'grey'
  })


const countAxis = padded.append('g.countAxis')
 .translate([0, marginalChartHeight - marginalBottomPadding]);

countAxis.append("g")
  .call(d3.axisTop().scale(countX).ticks(5).tickSizeOuter(0))
  .selectAll("text")
  .at({
    x: -2,
    textAnchor: 'end',
    opacity: 0.5
  });
  
countAxis.select('.tick').select('line')
  .at({
    y1: h-marginalChartHeight
  });
  
countAxis.append('text')
  .at({
    x: countBarWidth/2,
    y: h - marginalChartHeight+ 20,
  })
  .classed('axisTitles', true)
  .text('Set size')


const marginalCountAxis = padded.append("g")
  .translate([proportionPlotWidth,0])
  .call(d3.axisLeft().scale(marginalY).ticks(4).tickSizeOuter(0));

marginalCountAxis.selectAll("text")
  .attr('text-anchor', 'end')
  .attr('opacity', 0.5);

marginalCountAxis.select('text').remove() // hides the first zero so we can double use the one from the proportion chart. Hacky. 

// ----------------------------------------------------------------------
// Marginal bars. 
// ----------------------------------------------------------------------
const marginalCountsChart = padded.append('g.marginalCountsChart')
  .translate([proportionPlotWidth,0]);

const marginalBars = marginalCountsChart.selectAll('.marginalCounts')
  .data(options.marginalData)
  .enter().append('g')
  .translate(d => [matrixWidthScale(d.code), marginalY(d.count)])
  .on('mouseover',function(d){
    d3.select(this).selectAll('.margingMouseoverInfo').attr('opacity', 1);
  })
  .on('mouseout',function(d){
    d3.select(this).selectAll('.margingMouseoverInfo').attr('opacity', 0);
  })

marginalBars.append('rect')
  .at({
    height: d => marginalY(0) - marginalY(d.count),
    width: matrixWidthScale.bandwidth(),
    fill: 'orangered'
  })
  
marginalBars.append('rect')
  .at({
    y: d => -marginalY(d.count)-marginalBottomPadding,
    height: h,
    width: matrixWidthScale.bandwidth(),
    fillOpacity: 0.3,
    fill: highlightColor,
    stroke: 'black',
    rx: 5,
    opacity: 0,
    "class": "margingMouseoverInfo"
  })
  
  
marginalBars.append('text')
  .text(d => countFormat(d.count))
  .at({
    y: 0,
    x: d => -matrixWidthScale(d.code) - 20,
    textAnchor: 'end',
    fontWeight: 'bold',
    opacity: 0,
    "class": "margingMouseoverInfo"
  })
  
marginalBars.append('line')
  .text(d => countFormat(d.count))
  .at({
    y1: 0,y2:0,
    x1: d => -matrixWidthScale(d.code) - 20,
    x2: d => -matrixWidthScale(d.code),
    stroke: 'black',
    opacity: 0,
    "class": "margingMouseoverInfo"
  })
  
marginalBars.append('text')
  .html(d => `<tspan>Code:</tspan> ${d.code}`)
  .at({
    y: d => -marginalY(d.count) + marginalChartHeight/3,
    x: d => -matrixWidthScale(d.code) - countBarWidth,
    fontSize: 24,
    textAnchor: 'start',
    opacity: 0,
    "class": "margingMouseoverInfo"
  })