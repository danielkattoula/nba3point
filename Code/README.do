* HEADS UP: Most of the code will run right away but the last figure takes around 2-4 minutes to load. 
* REPLICATE THE DATA (THIS WILL TAKE SEVERAL HOURS TO RUN): run nba_scraper_replicable.py in termnial. Will result in three csv files, save under "RawData" in appropriate folder. 
* OR, just use csv files already saved in "RawData".
clear all

* SET WORKING DIRECTORY (CHANGE ONLY THIS + LOG FILE)
cd "EDIT THIS"

* OPEN LOG FILE (RENAME)
log using EDITTHIS.txt, text replace


* BUILD DATASET
do Code/nbabuild


* GENERATE DESCRIPTIVE FIGURES
do Code/nbadescriptive


* RUN REGRESSIONS
do Code/nbaregressions


log close
