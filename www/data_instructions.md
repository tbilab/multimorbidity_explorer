## Preloaded data

Supplied is a simulated phewas result and individual data for testing the app. Note that these results are entirely synthetic and so any patterns you may find are spurious, unfortunately.

## Input Data format

There are three required files for loading data into the public facing version of MultimorbidityExplorer. All files are required to be in `.csv` format.

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

