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
  'nstrayer/network3d',
  'DivadNojnarg/shinydashboardPlus'
)
devtools::install_github(github_packages)
```

Now that this is done simply navigate to `app.R` and press the 'Run App' button. 

## Screenshots

__Data Entry/ Landing Page__

![](https://github.com/tbilab/multimorbidity_explorer/raw/master/screenshots/data_loading.png)

__Main App/ Dashboard__
![](https://raw.githubusercontent.com/tbilab/multimorbidity_explorer/master/screenshots/main_app_new.png)



## Input Data format

If you wish to use your own custom data, there are three required files for loading data into the public facing version of MultimorbidityExplorer. All files are required to be in `.csv` format.

These files are: 

__Phewas results file__: This file contains the results of the (most likely) univariate statistical analysis correlating each phenotype code to your SNP or biomarker of interest. The columns are

- `code`: character value uniquely denoting a given phenotype
- `category`: A hierarchical category denoting some grouping structure in your phenotypes. For instance all codes related to 'infectious diseases'. These categories are used in coloring the manhattan plot.
- `p_val`: The p-value associated with your statistical test associating the given phenotype code with the biomarker of interest. 
- `tooltip`: Any interesting information about the code can be put here. It will show up as text on mouseover of the code in the manhattan or network plots. Allows use html formating of any kind for tables etc.

If a tooltip column is not included then the app will automatically make one by just displaying each code's column values next to the column title. 


__ID to SNP file__: Mapping between individual's IDs and the number of copies of the minor allele they have for the SNP of interest. A row is only needed if an individual has one or more copies of the minor allele (but data provided with rows for zero copies will work as well, just be less space efficient). 

- `IID`: Unique identifying character ID for each individual in your data. 
- `snp`: Integer corresponding to the number of copies of the minor allele the individual possesses. 


__ID to phenome file__: A mapping between an individuals ID and present phenotypes. If an individual has 10 present phenotypes they will have 10 rows in this csv; 25 phenotypes: 25 rows, etc.. Columns are: 

- `IID`: Unique identifying character ID for each individual (matches same column in __ID to SNP file__.)
- `code`: Unique identifying character ID for a given phenotype. This should match the column of the same name in __Phewas results file__.

## Preloading data into the app

If you want to use preloaded data instead of manually inputting the files, you can place it into a folder `data/preloaded`. 

The format of the spreadsheets is the same as you would provide for the manual data entry. The snp specific files (id_to_snp.csv and phewas_results.csv) will go in a folder with the name of whatever snp you are working with (e.g. `rs123456/`). Since the phenome spreadsheet doesn't change it is placed just at `data/preloaded/id_to_code.csv` so it can be shared across the snps you have.  The file structure should look like this: 

```
# path = data/preloaded
id_to_code.csv
rs123456/
  id_to_snp.csv
  phewas_results.csv
rs7891011/
  id_to_snp.csv
  phewas_results.csv
...
```

The app will automatically detect the present snps and list them in a dropdown for you. 