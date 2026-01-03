# nba3point
This project examines the question: What factors are associated with three-point shooting accuracy in the NBA? The results represent associations rather than causal effects, as shot outcomes and shot selection may be influenced by unobserved factors such as shot difficulty, defensive pressure, or in-game context.

The code folder contains all files necessary to replicate the data construction and analysis. This includes a fully replicable NBA shot-level data scraper, along with the following .do files: nbabuild.do, nbadescriptive.do, nbaregressions.do, and a master README.do. The scraper retrieves all three-point shot attempts (both made and missed) and outputs three CSV files, which serve as the inputs for the analysis.

To reproduce the results, the user only needs to:

Run the NBA scraper file to generate the three CSV datasets.

Run the readme.do file, changing only the cd directory line and the logfile name.

All data cleaning, variable construction, descriptive statistics, and regression analyses are automated through these scripts.

The results folder contains all output from the analysis, including regression tables and graphical figures. In addition, a PowerPoint file is included that summarizes the empirical findings and discusses the main results of the project.
