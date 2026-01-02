*************************************
* IMPORT AND APPEND ANNUAL DATASETS *
*************************************

* IMPORT DATA SETS FOR THREE SEASONS
foreach season in "2015-16" "2019-20" "2023-24" {
    di "Season `season'"
    import delimited "RawData/`season'_SHOTS_UPDATED.csv", clear
    
    
    save "CleanData/nba_`season'.dta", replace
    clear
}

* APPEND ALL DATASETS INTO ONE
use "CleanData/nba_2015-16.dta", clear
append using "CleanData/nba_2019-20.dta"
append using "CleanData/nba_2023-24.dta"

* SAVE COMBINED RAW DATA
save "CleanData/NBA_combined.dta", replace
clear

************************************
* DATA CLEANING AND VARIABLE SETUP *
************************************

use "CleanData/NBA_combined.dta", clear

* RENAME KEY VARIABLES FIRST 
rename shot_dist shot_distance
rename player_height height
rename player_weight weight
rename player_position position
rename player_age age
rename player_birthd~e player_birthdate

* KEEP CRUCIAL VARIABLES 
keep season_1 team_id team_name player_id player_name game_date game_id home_team away_team event_type shot_made action_type shot_type zone_name zone_abb zone_range loc_x loc_y shot_distance quarter mins_left secs_left height weight position player_birthdate age

***************************
* GENERATE NEW VARIABLES  *
***************************

* VERIFY WE ONLY HAVE 3-POINT SHOTS FIRST
tab shot_type
keep if shot_type == "3PT Field Goal"

* CREATE BINARY OUTCOME VARIABLE FOR MADE 3-POINTER
* shot_made is already 0/1 numeric, just rename it
rename shot_made made_3pt
label var made_3pt "Made 3-pointer (1=Yes, 0=No)"

* LABEL RENAMED VARIABLES
label var shot_distance "Shot distance from basket (feet)"
label var height "Player height"
label var weight "Player weight (lbs)"
label var position "Player position"
label var age "Player age"

* SEASON YEAR VARIABLE
* season_2 is empty, so create season_year from season_1 string
gen season_year = .
replace season_year = 2016 if regexm(season_1, "2015")
replace season_year = 2020 if regexm(season_1, "2019")
replace season_year = 2024 if regexm(season_1, "2023")

label define season_year 2016 "2015-16" 2020 "2019-20" 2024 "2023-24"
label values season_year season_year
label var season_year "NBA Season"

* QUARTER VARIABLE
tab quarter
* Recode any overtime periods beyond 5 as 5 (OT)
replace quarter = 5 if quarter > 5 & quarter < .
* Drop any observations with impossible quarter values
drop if quarter < 1 | quarter == .
label define quarter 1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4" 5 "OT"
label values quarter quarter
label var quarter "Quarter"

* TIME REMAINING VARIABLES
label var mins_left "Minutes remaining in quarter"
label var secs_left "Seconds remaining in quarter"

* CALCULATE TOTAL TIME REMAINING IN GAME (in seconds)
gen time_remaining = .
replace time_remaining = (4 - quarter) * 720 + mins_left * 60 + secs_left if quarter <= 4
replace time_remaining = mins_left * 60 + secs_left if quarter > 4
label var time_remaining "Total seconds remaining in game"

* CALCULATE TIME ELAPSED IN QUARTER
gen time_elapsed_quarter = (15 - mins_left) * 60 + (60 - secs_left)
replace time_elapsed_quarter = 0 if time_elapsed_quarter < 0
label var time_elapsed_quarter "Seconds elapsed in current quarter"

* POSITION DUMMY VARIABLES
gen pos_guard = regexm(position, "Guard")
gen pos_forward = regexm(position, "Forward") 
gen pos_center = regexm(position, "Center")
label var pos_guard "Guard position"
label var pos_forward "Forward position"  
label var pos_center "Center position"

* CONVERT HEIGHT TO NUMERIC INCHES (from format like "6-8")
gen height_feet = real(substr(height, 1, 1))
gen height_inches_part = real(substr(height, 3, 2))
gen height_total_inches = height_feet * 12 + height_inches_part
label var height_total_inches "Player height (total inches)"

* CALCULATE EXPERIENCE (approximate)
gen experience_proxy = age - 19
replace experience_proxy = 0 if experience_proxy < 0
label var experience_proxy "Approximate years of experience"

* PLAYER AND TEAM ID VARIABLES
encode player_name, gen(player_id_encoded)
label var player_id "Player ID number"

encode team_name, gen(team_id_encoded)
label var team_id "Team ID number"

* HOME GAME INDICATOR 

* Create team abbreviation variable based on team_name
gen team_abb = ""
replace team_abb = "ATL" if team_name == "Atlanta Hawks"
replace team_abb = "BOS" if team_name == "Boston Celtics"
replace team_abb = "BKN" if team_name == "Brooklyn Nets"
replace team_abb = "CHA" if team_name == "Charlotte Hornets"
replace team_abb = "CHI" if team_name == "Chicago Bulls"
replace team_abb = "CLE" if team_name == "Cleveland Cavaliers"
replace team_abb = "DAL" if team_name == "Dallas Mavericks"
replace team_abb = "DEN" if team_name == "Denver Nuggets"
replace team_abb = "DET" if team_name == "Detroit Pistons"
replace team_abb = "GSW" if team_name == "Golden State Warriors"
replace team_abb = "HOU" if team_name == "Houston Rockets"
replace team_abb = "IND" if team_name == "Indiana Pacers"
replace team_abb = "LAC" if team_name == "LA Clippers"
replace team_abb = "LAL" if team_name == "Los Angeles Lakers"
replace team_abb = "MEM" if team_name == "Memphis Grizzlies"
replace team_abb = "MIA" if team_name == "Miami Heat"
replace team_abb = "MIL" if team_name == "Milwaukee Bucks"
replace team_abb = "MIN" if team_name == "Minnesota Timberwolves"
replace team_abb = "NOP" if team_name == "New Orleans Pelicans"
replace team_abb = "NYK" if team_name == "New York Knicks"
replace team_abb = "OKC" if team_name == "Oklahoma City Thunder"
replace team_abb = "ORL" if team_name == "Orlando Magic"
replace team_abb = "PHI" if team_name == "Philadelphia 76ers"
replace team_abb = "PHX" if team_name == "Phoenix Suns"
replace team_abb = "POR" if team_name == "Portland Trail Blazers"
replace team_abb = "SAC" if team_name == "Sacramento Kings"
replace team_abb = "SAS" if team_name == "San Antonio Spurs"
replace team_abb = "TOR" if team_name == "Toronto Raptors"
replace team_abb = "UTA" if team_name == "Utah Jazz"
replace team_abb = "WAS" if team_name == "Washington Wizards"


gen home_game = (team_abb == home_team)
label var home_game "Playing at home (1=Yes, 0=No)"

label var team_abb "Team abbreviation"

* SHOT LOCATION VARIABLES
label var loc_x "Shot location X coordinate"
label var loc_y "Shot location Y coordinate"
label var shot_distance "Distance from basket (feet)"

* SHOT DISTANCE CATEGORIES
egen shot_dist_cat = cut(shot_distance), at(22, 24, 26, 28, 30, 50)
label define shot_dist_cat 22 "22-23 ft" 24 "24-25 ft" 26 "26-27 ft" 28 "28-29 ft" 30 "30+ ft"
label values shot_dist_cat shot_dist_cat
label var shot_dist_cat "Shot distance category"

* ENCODE ZONE VARIABLES
encode zone_name, gen(zone_name_num)
encode zone_abb, gen(zone_abb_num)
encode zone_range, gen(zone_range_num)

* ENCODE ACTION TYPE
encode action_type, gen(action_type_num)
label var action_type_num "Shot action type (numeric)"

* GAME DATE VARIABLE
gen date_year = real(substr(game_date, 1, 4))
gen date_month = real(substr(game_date, 6, 2))
gen date_day = real(substr(game_date, 9, 2))
gen game_date_numeric = mdy(date_month, date_day, date_year)
format game_date_numeric %td
label var game_date_numeric "Game date"
drop date_year date_month date_day

***************************
* DATA QUALITY CHECKS     *
***************************

* CHECK FOR MISSING VALUES
misstable summarize made_3pt shot_distance quarter player_id age height_total_inches

* DROP OBSERVATIONS WITH MISSING KEY VARIABLES
drop if missing(shot_distance)
drop if missing(quarter)

* CHECK REASONABLE VALUES
summarize shot_distance quarter age height_total_inches weight made_3pt

* COUNT EXTREME OUTLIERS
count if shot_distance < 22 | shot_distance > 50

* VERIFY HOME GAME VARIABLE WORKED
di _newline "Checking home_game variable distribution:"
tab home_game
sum home_game

***************************
* SAVE FINAL CLEAN DATA   *
***************************

* KEEP ONLY NECESSARY VARIABLES 
keep made_3pt shot_distance quarter mins_left secs_left time_remaining player_id player_name player_id_encoded age height height_total_inches weight position pos_guard pos_forward pos_center experience_proxy team_id team_name team_abb team_id_encoded home_game season_year game_id game_date game_date_numeric action_type action_type_num shot_type event_type zone_name zone_abb zone_range zone_name_num zone_abb_num zone_range_num loc_x loc_y shot_dist_cat home_team away_team

* ORDER VARIABLES LOGICALLY 
order season_year game_id game_date game_date_numeric quarter mins_left secs_left time_remaining player_id player_name team_id team_name home_game made_3pt shot_distance shot_dist_cat position pos_guard pos_forward pos_center age experience_proxy height height_total_inches weight action_type zone_name

* LABEL DATASET
label data "NBA 3-Point Shot Data: 2015-16, 2019-20, 2023-24 seasons"

* SAVE FINAL CLEAN DATA
compress
save "CleanData/NBA_final.dta", replace

* DISPLAY SUMMARY STATISTICS
di _newline(2)
di "************************************"
di "* DATA CLEANING COMPLETE           *"
di "************************************"
di _newline
di "Final number of observations: " _N
di _newline
di "Observations by season:"
tab season_year
di _newline
di "Shot outcomes:"
tab made_3pt
di _newline
di "Shots by position:"
tab position
di _newline
di "Summary of key continuous variables:"
summarize shot_distance age height_total_inches weight made_3pt
