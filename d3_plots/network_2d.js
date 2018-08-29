const padding = 20;
const div_padding_bottom = 0;
const div_padding_left = 0;
const tooltip_offset = 15;

const case_radius = 2;
const case_opacity = 1;

const edge_color = '#aaa';
const edge_opacity = options.just_snp ? 0.2: 0.07;

const small_edge = width < height ? width: height,
      OUTER_RING_RADIUS = (small_edge/2)*0.35,
      INNER_RING_RADIUS = (small_edge/2)*0.01;

let selected_codes = [];

const container = d3.select(canvas.node().parentElement);
container.style('position', 'relative');

const context = canvas.node().getContext('2d');

let current_transform = d3.zoomIdentity;

// append the date to the begining so sent value always changes. 
const sendCodeVector = (selectedCodes) => [Date.now().toString(), ...selected_codes];

function sendMessage(type, selected_codes = []){

  Shiny.onInputChange(
    options.msg_loc,
    {
      type,
      payload: sendCodeVector(selected_codes)
    }
  );
    
};


const svg = container.selectAppend('svg')
  .st({
    position: 'absolute',
    bottom: div_padding_bottom, 
    left: div_padding_left,
    width: width, 
    height: height
  });
  
const tooltip = container.selectAppend('div.network_tooltip')
  .attr('class', 'network_tooltip')
  .st({
    background:'white',
    borderRadius: '10px',
    padding: '0px 15px',
    boxShadow: '1px 1px 3px black',
    position:'fixed',
    display: 'none'
  });
  
const button_span = {
  border: "1px solid black",
  padding: "5px",
  borderRadius: "8px",
  boxShadow: "black 1px 1px 0px",
  background: "lightyellow",
  cursor: "pointer",
  paddingRight: "5px"
};

const node_interaction_popup = container.selectAppend('div.node_interaction_popup')
  .attr('class', 'node_interaction_popup')
  .st({
    background:'white',
    position:'absolute',
    display: 'none'
  });
  

const delete_codes_button = node_interaction_popup
  .selectAppend('span#delete_button')
  .attr('id', 'delete_button')
  .st(button_span)
  .text('Delete Codes')
  .on('click', () => {
    sendMessage('delete', selected_codes);
  });
  
const isolate_codes_button = node_interaction_popup
  .selectAppend('span#isolate_button')
  .attr('id', 'isolate_button')
  .st(button_span)
  .text('Isolate Codes')
  .on('click', () => {
    sendMessage('isolate', selected_codes);
  });
 
if(options.just_snp){
  const invert_codes_button = node_interaction_popup
    .selectAppend('button#invert_button')
    .attr('id', 'invert_button')
    .st(button_span)
    .text('Invert Codes')
    .on('click', () => {
      sendMessage('invert', selected_codes);
    });  
} 

  
const hidden_style = {
  display: 'none',
  left: -1000
};
const displayed_style = {
  bottom: '10px',
  left: '10px',
  display:'block'
};

const vertices = data.vertices;
vertices.forEach(d => d.pheno = d.selectable);
const links = data.edges.map(d => ({source: +d.source, target: +d.target}));

svg.html(''); // wipe svg clean in case we've reloaded the viz. 
const pheno_circs = svg.selectAll('circle')
  .data(vertices, d => d.name)
  .enter()
  .filter(d => d.pheno)
  .append('circle')
  .at({
    r: 10,
    cx: 0,
    cy: 0,
    stroke: d => d.inverted ?  d.color: 'black',
    strokeWidth: d => d.inverted ? 3: 0,
    fill: d => d.inverted ? 'white': d.color,
  })
  .on('click', function(d){
    // Is code already selected?
    const selected_already = selected_codes.includes(d.name);
    
    if(selected_already){
      // pull code out of selected list
      selected_codes = selected_codes.filter(code => code !== d.name);
      // get rid of selection boundry
      d3.select(this)
        .at({
          strokeWidth: d => d.inverted ? 3: 0,
          fill: d => d.inverted ? 'white': d.color,
        });
    } else {
      // add code to selected codes list
      selected_codes = [d.name, ...selected_codes];
      d3.select(this)
        .at({
          strokeWidth: d => d.inverted ? 3: 2,
          fill: d => d.inverted ? 'black': d.color,
        });
    }
    
    // do we have selected codes currently? If so display the action popup.
    if(selected_codes.length > 0){
      node_interaction_popup.st(displayed_style);
    } else {
      node_interaction_popup.st(hidden_style);
    }
  })
  .on('mouseover', function(d){
    d3.select(this).attr('r', 15);
    tooltip
      .html(d.tooltip)
      .st({
        top: `${d3.event.clientY + tooltip_offset}px`,
        left:`${d3.event.clientX + tooltip_offset}px`,
        display:'block'
      });
  })
  .on('mouseout', function(){
    d3.select(this).attr('r', 10);
    tooltip
      .st(hidden_style);
  });
  
  
const x = d3.scaleLinear()
  .range([padding, width-padding]);
  
const y = d3.scaleLinear()
  .range([padding,height-padding]);

const simulation = d3.forceSimulation(vertices)
    .force("link", 
      d3.forceLink(links)
        .id(d => d.id)
        .distance(1)
        .strength(0.6)
    )
    .force("charge", 
      d3.forceManyBody()
        .strength(-8)
    )
    .force("xAxis",d3.forceX(width/2))
    .force("yAxis",d3.forceY(height/2))
    .on("tick", ticked);
  
svg.call(
  d3.zoom()
    .scaleExtent([0.5, 5])
    .on("zoom", zoom)
);

function zoom(){
  current_transform = d3.event.transform;
  ticked();
}

function ticked() {
  x.domain(d3.extent(vertices, d => d.x));
  y.domain(d3.extent(vertices, d => d.y));
  
  const zoomed_x = current_transform.rescaleX(x);
  const zoomed_y = current_transform.rescaleY(y);
  
  // update phenotype svg circles
  pheno_circs
    .at({
      cx: d => zoomed_x(d.x),
      cy: d => zoomed_y(d.y)
    });

  context.clearRect(0, 0, width, height);
  context.save();
  context.globalAlpha = edge_opacity;
  
  context.beginPath();
  links.forEach(d => {
    context.moveTo(zoomed_x(d.source.x), zoomed_y(d.source.y));
    context.lineTo(zoomed_x(d.target.x), zoomed_y(d.target.y));
  });  

  context.strokeStyle = edge_color;
  context.stroke();
  
  // Draw cases
  context.globalAlpha = case_opacity;
  vertices.forEach( d => {
    if(!d.pheno){
      context.strokeStyle = `rgba(0, 0, 0, 0)`;
      context.fillStyle = d.color;
      
      context.beginPath();
      context.arc(zoomed_x(d.x), zoomed_y(d.y), case_radius, 0, 2 * Math.PI);
      context.fill();
      context.stroke();
    }
  });
  
  context.restore();
}