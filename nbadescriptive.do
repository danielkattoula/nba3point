**********************************************
* NBA 3-POINT SHOOTING: DESCRIPTIVE FIGURES *
**********************************************

* LOAD CLEAN DATA
use "CleanData/NBA_final.dta", clear

* CREATE RESULTS FOLDER IF IT DOESN'T EXIST
cap mkdir "Results"

**********************************************
* FIGURE 1: DISTRIBUTION OF 3-PT ACCURACY BY PLAYER
**********************************************

* Calculate shooting percentage for each player (minimum 50 attempts)
preserve
    collapse (mean) shooting_pct=made_3pt (count) attempts=made_3pt, by(player_id player_name)
    
    * Convert to percentage
    replace shooting_pct = shooting_pct * 100
    
    * Keep only players with 50+ attempts for meaningful statistics
    keep if attempts >= 50
    
    * Create histogram of shooting percentages
    histogram shooting_pct, width(2) percent color(navy) title("Distribution of 3-Point Shooting Accuracy Across NBA Players") subtitle("Players with 50+ Attempts, 2015-16, 2019-20, 2023-24 Seasons") xtitle("3-Point Shooting Percentage") ytitle("Percent of Players") xlabel(15(5)55) note("Data Source: NBA Stats API")
    
    graph export "Results/figure1_shooting_distribution.png", replace width(2000)
    
    * Summary statistics for the slide notes
    summarize shooting_pct, detail
    di "Mean shooting %: " %4.1f r(mean)
    di "Median shooting %: " %4.1f r(p50)
    di "Std dev: " %4.1f r(sd)
restore

**********************************************
* FIGURE 2: SHOT DISTANCE VS 3-PT ACCURACY
**********************************************

* Create binned shot distance categories and calculate accuracy
preserve
    * Create 1-foot bins for shot distance
    gen dist_bin = floor(shot_distance)
    
    * Calculate mean accuracy by distance bin
    collapse (mean) accuracy=made_3pt (count) n=made_3pt, by(dist_bin)
    
    * Keep distances between 22-35 feet (main 3PT range)
    keep if dist_bin >= 22 & dist_bin <= 35
    
    * Convert to percentage
    replace accuracy = accuracy * 100
    
    * Create scatter plot with line
    twoway (scatter accuracy dist_bin, mcolor(navy) msize(medium)) (lfit accuracy dist_bin, lcolor(cranberry) lwidth(medthick)), title("3-Point Accuracy by Shot Distance") subtitle("2015-16, 2019-20, 2023-24 Seasons") xtitle("Distance from Basket (feet)") ytitle("3-Point Shooting Percentage") xlabel(22(2)35) ylabel(30(5)40) legend(order(1 "Actual" 2 "Linear Fit") position(6) rows(1)) note("Data Source: NBA Stats API")
    
    graph export "Results/figure2_distance_accuracy.png", replace width(2000)
restore

**********************************************
* FIGURE 3: 3-PT ACCURACY TRENDS ACROSS SEASONS
**********************************************

* Calculate accuracy by season
preserve
    collapse (mean) accuracy=made_3pt (count) attempts=made_3pt, by(season_year)
    
    * Convert to percentage
    replace accuracy = accuracy * 100
    
    * Create line plot with markers
    twoway (line accuracy season_year, lcolor(navy) lwidth(thick)) (scatter accuracy season_year, msymbol(O) mcolor(navy) msize(large)), title("3-Point Shooting Accuracy Trends Over Time") subtitle("League-Wide Evolution 2015-2024") xtitle("Season") ytitle("3-Point Shooting Percentage") xlabel(2016 "2015-16" 2020 "2019-20" 2024 "2023-24") ylabel(34(0.5)37) legend(off) note("Data Source: NBA Stats API. Total shots: 213,900")
    
    graph export "Results/figure3_season_trends.png", replace width(2000)
    
    * List the exact values
    list season_year accuracy attempts
restore

**********************************************
* FIGURE 4: 3-PT ACCURACY BY POSITION
**********************************************

* Calculate accuracy by position
preserve
    * Remove missing positions
    drop if missing(position)
    
    collapse (mean) accuracy=made_3pt (count) attempts=made_3pt, by(position)
    
    * Convert to percentage
    replace accuracy = accuracy * 100
    
    * Sort by accuracy for better visualization
    gsort -accuracy
    
    * Create horizontal bar chart
    graph hbar accuracy, over(position, sort(accuracy) descending) title("3-Point Shooting Accuracy by Player Position") subtitle("2015-16, 2019-20, 2023-24 Seasons") ytitle("3-Point Shooting Percentage") ylabel(30(5)45) bar(1, color(orange)) blabel(bar, format(%4.1f)) note("Data Source: NBA Stats API")
    
    graph export "Results/figure4_position_accuracy.png", replace width(2000)
    
    * List the values
    list position accuracy attempts
restore

**********************************************
* FIGURE 5: SHOOTING BY COURT ZONE
**********************************************

* Calculate accuracy by zone
preserve
    collapse (mean) accuracy=made_3pt (count) attempts=made_3pt, by(zone_name)
    
    * Convert to percentage
    replace accuracy = accuracy * 100
    
    * Keep zones with at least 1000 attempts
    keep if attempts >= 1000
    
    * Sort by accuracy
    gsort -accuracy
    
    * Create horizontal bar chart
    graph hbar accuracy, over(zone_name, sort(accuracy) descending label(labsize(small))) title("3-Point Shooting Accuracy by Court Zone") subtitle("Zones with 1000+ Attempts") ytitle("3-Point Shooting Percentage") bar(1, color(navy)) blabel(bar, format(%4.1f) size(small)) note("Data Source: NBA Stats API")
    
    graph export "Results/figure5_zone_accuracy.png", replace width(2000)
    
    * List the values
    list zone_name accuracy attempts
restore

**********************************************
* SUMMARY STATISTICS TABLE
**********************************************

* Generate comprehensive summary statistics
preserve
    * Key variables summary
    summarize made_3pt shot_distance age height_total_inches weight
    
    * Output to log
    di _newline(2)
    di "======================================"
    di "SUMMARY STATISTICS - KEY VARIABLES"
    di "======================================"
    
    * More detailed summary
    tabstat made_3pt shot_distance age height_total_inches weight, statistics(n mean sd min max p25 p50 p75) columns(statistics) format(%9.2f)
restore

* Observations by season and position
di _newline(2)
di "======================================"
di "SAMPLE COMPOSITION"
di "======================================"

tab season_year, missing
tab position if !missing(position), sort

di _newline
di "======================================"
di "DESCRIPTIVE FIGURES COMPLETE"
di "======================================"
di "All figures saved to Results folder"
