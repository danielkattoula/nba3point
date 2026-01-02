**********************************************
* NBA 3-POINT SHOOTING: REGRESSION ANALYSIS *
**********************************************

* LOAD CLEAN DATA
use "CleanData/NBA_final.dta", clear

* CREATE RESULTS FOLDER IF IT DOESN'T EXIST
cap mkdir "Results"

**********************************************
* PREPARE VARIABLES FOR REGRESSION
**********************************************

* Drop observations with missing key variables
drop if missing(shot_distance)
drop if missing(quarter)
drop if missing(age)
drop if missing(height_total_inches)
drop if missing(weight)
drop if missing(position)

* Summary of final regression sample
di _newline(2)
di "======================================"
di "REGRESSION SAMPLE"
di "======================================"
di "Total observations: " _N
tab season_year
tab position

**********************************************
* REGRESSION 1: SHOT-SPECIFIC FACTORS ONLY
**********************************************

di _newline(2)
di "======================================"
di "REGRESSION 1: SHOT-SPECIFIC FACTORS"
di "======================================"

reg made_3pt shot_distance i.quarter home_game i.season_year, cluster(player_id)
estimates store reg1

**********************************************
* REGRESSION 2: ADD PLAYER CHARACTERISTICS
**********************************************

di _newline(2)
di "======================================"
di "REGRESSION 2: + PLAYER CHARACTERISTICS"
di "======================================"

reg made_3pt shot_distance i.quarter home_game age height_total_inches weight experience_proxy pos_guard pos_forward i.season_year, cluster(player_id)
estimates store reg2

**********************************************
* REGRESSION 3: ADD TEAM FACTORS
**********************************************

di _newline(2)
di "======================================"
di "REGRESSION 3: + TEAM FACTORS"
di "======================================"

reg made_3pt shot_distance i.quarter home_game age height_total_inches weight experience_proxy pos_guard pos_forward i.season_year i.team_id_encoded, cluster(player_id)
estimates store reg3

**********************************************
* REGRESSION 4: PLAYER FIXED EFFECTS
**********************************************

di _newline(2)
di "======================================"
di "REGRESSION 4: PLAYER FIXED EFFECTS"
di "======================================"

xtset player_id_encoded
xtreg made_3pt shot_distance i.quarter home_game i.season_year, fe cluster(player_id_encoded)
estimates store reg4

**********************************************
* REGRESSION FIGURE 1: COEFFICIENT PLOT
**********************************************

di _newline(2)
di "======================================"
di "CREATING COEFFICIENT PLOT"
di "======================================"

cap which coefplot
if _rc != 0 {
    di "Installing coefplot..."
    ssc install coefplot
}

coefplot reg2, keep(shot_distance age height_total_inches weight experience_proxy pos_guard pos_forward home_game) xline(0, lcolor(red) lpattern(dash)) xlabel(, format(%4.3f)) title("Factors Affecting 3-Point Shooting Accuracy") subtitle("Coefficient Estimates with 95% Confidence Intervals") xtitle("Coefficient Estimate (Percentage Point Change in 3PT%)") coeflabels(shot_distance = "Shot Distance (feet)" age = "Player Age (years)" height_total_inches = "Height (inches)" weight = "Weight (lbs)" experience_proxy = "Experience (years)" pos_guard = "Guard Position" pos_forward = "Forward Position" home_game = "Home Game") graphregion(color(white)) scheme(s2color)

graph export "Results/reg_figure1_coefplot.png", replace

**********************************************
* REGRESSION FIGURE 2: MARGINAL EFFECTS
* Shot Distance by Experience Level - FLEXIBLE SPECIFICATION
**********************************************

di _newline(2)
di "======================================"
di "CREATING MARGINAL EFFECTS PLOT - FLEXIBLE DISTANCE"
di "======================================"

* Create experience categories
gen exp_cat = 1 if experience_proxy < 3
replace exp_cat = 2 if experience_proxy >= 3 & experience_proxy < 7
replace exp_cat = 3 if experience_proxy >= 7 & experience_proxy < .
label define exp_cat 1 "0-2 years" 2 "3-6 years" 3 "7+ years"
label values exp_cat exp_cat
label var exp_cat "Experience Level"

* Create distance dummies (round to whole feet)
gen distance_feet = floor(shot_distance)
label var distance_feet "Shot distance (whole feet)"

* Check distribution of distance_feet
tab distance_feet if distance_feet >= 22 & distance_feet <= 30

reg made_3pt i.distance_feet##i.exp_cat i.quarter i.season_year home_game, cluster(player_id)

* Generate margins at each distance for each experience group
margins exp_cat, at(distance_feet=(22(1)30))

* Create marginsplot with better y-axis formatting
marginsplot, ///
    title("Predicted 3-Point Accuracy by Shot Distance and Experience") ///
    subtitle("Flexible Distance Specification") ///
    xtitle("Shot Distance (feet)") ///
    ytitle("Predicted 3-Point Percentage") ///
    ylabel(0.20(0.05)0.45, angle(0) format(%4.2f)) ///
    xlabel(22(1)30) ///
    legend(order(1 "0-2 years" 2 "3-6 years" 3 "7+ years") ///
        position(6) rows(1)) ///
    plot1opts(lcolor(navy) mcolor(navy) lwidth(medthick)) ///
    plot2opts(lcolor(orange) mcolor(orange) lwidth(medthick)) ///
    plot3opts(lcolor(green) mcolor(green) lwidth(medthick)) ///
    graphregion(color(white)) ///
    scheme(s2color)

* Export figure
graph export "Results/reg_figure2_margins_FLEXIBLE.png", replace width(2000)

* Display some key coefficients from the flexible model
di _newline(2)
di "======================================"
di "FLEXIBLE MODEL: SELECTED COEFFICIENTS"
di "======================================"
di "Note: Model includes separate dummy for each distance (22-30 feet)"
di "      interacted with experience categories"
di "Total parameters estimated: " e(df_m)

**********************************************
* SUMMARY TABLE: COMPARE ALL REGRESSIONS
**********************************************

di _newline(2)
di "======================================"
di "REGRESSION COMPARISON TABLE"
di "======================================"

estimates table reg1 reg2 reg3 reg4, keep(shot_distance home_game age experience_proxy pos_guard) stats(N r2 r2_a) star(0.10 0.05 0.01)

**********************************************
* CREATE REGRESSION TABLE MANUALLY
**********************************************

di _newline(2)
di "======================================"
di "REGRESSION RESULTS TABLE"
di "======================================"

esttab reg1 reg2 reg3 reg4 using "Results/regression_table.csv", replace b(4) se(4) r2 ar2 star(* 0.10 ** 0.05 *** 0.01) keep(shot_distance 2.quarter 3.quarter 4.quarter 5.quarter home_game age height_total_inches weight experience_proxy pos_guard pos_forward) title("NBA 3-Point Shooting Accuracy Regressions") mtitles("(1) Shot Factors" "(2) + Player" "(3) + Team FE" "(4) Player FE")

di "======================================"
di "REGRESSION ANALYSIS COMPLETE"
di "======================================"
di "All results saved to Results folder"
di "New flexible distance figure: reg_figure2_margins_FLEXIBLE.png"
