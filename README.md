# Multimorbidity Explorer

An application developed in the TBI-Lab at Vanderbilt University for exploring and visualizing the results of PheWAS studies with a goal towards uncovering multi-phenotype patterns of association. 


## Installation

__Prerequisites:__ Installation of a recent version of RStudio capable of running Shiny apps. 

To install the app you must first clone the repository however you choose. 

```bash
git clone git@github.com:tbilab/multimorbidity_explorer.git
```

Once you have opened the project/repo in RStudio you will need to make sure you have a few R packages installed. To install or verify you already have them installed, run the following lines of code in your R console. 

```r
cran_packages <- c(
  'shiny',
  'shinydashboard',
  'tidyverse',
  'here',
  'magrittr',
  'plotly',
  'r2d3',
  'devtools'
)

install.packages(cran_packages)

github_packages <- c(
  'nstrayer/network3d'
)
devtools::install_github(github_packages)
```

Now that this is done simply navigate to `app.R` and press the 'Run App' button. 

## Screenshots

__Data Entry/ Landing Page__

![](https://github.com/tbilab/multimorbidity_explorer/raw/master/screenshots/data_entry.png)

__Main App/ Dashboard__
![](https://github.com/tbilab/multimorbidity_explorer/raw/master/screenshots/main_app.png)
