
clear all

***********************************************************
* Importing database 
***********************************************************

** Set your own working directory

use "C:\Users\Ignacia Rivera\Desktop\GitHub\access_regimes_stewardship_ssf\Data\DB_fishers.dta"

***********************************************************
* Generating new variables for analysis 
***********************************************************

** Percent of compliance for each individual in each round
g compliance = ((50 - overextraction)*100)/50

** Adjusting rounds for each stage to go from 0 to 9 

generate rounds_open = 0
replace rounds_open = round - 1 if round < 11

generate rounds_enfr = 0
replace rounds_enfr = round - 11 if round >= 11

** Variable for stage 

generate stage = .
replace stage = 1 if round < 11
replace stage = 2 if round >= 11


** Generating dummies for treatment variables 

generate HP = performance == 1
generate LP = performance == 2

generate loco = framing == 1
generate hake = framing == 2

generate open = stage == 1
generate enfr = stage == 2

** Generating multiplicative variables for interaction terms

generate loco_HP   = loco * HP
generate enfr_HP   = enfr * HP
generate enfr_loco = enfr * loco

generate HP_loco_rounds_open = HP * loco * rounds_open
generate HP_loco_rounds_enfr = HP * loco * rounds_enfr
generate HP_hake_rounds_open = HP * hake * rounds_open
generate HP_hake_rounds_enfr = HP * hake * rounds_enfr

generate LP_loco_rounds_open = LP * loco * rounds_open
generate LP_loco_rounds_enfr = LP * loco * rounds_enfr
generate LP_hake_rounds_open = LP * hake * rounds_open
generate LP_hake_rounds_enfr = LP * hake * rounds_enfr

***********************************************************
* OLS to test the effect of treatment variables on 
* group compliance 
***********************************************************

** Preserving original database before collapsing into means
preserve 

** Aggregating mean compliance by group
collapse compliance HP loco enfr loco_HP - LP_hake_rounds_enfr, by(group_id stage round)	

** Regenerating variables with rounds per stage 
generate rounds_open = 0
replace rounds_open = round - 1 if round < 11

generate rounds_enfr = 0
replace rounds_enfr = round - 11 if round >= 11

* OLS models group compliance ~ treatment variables

*** Model 1
regress  compliance HP loco enfr, r
estat ic

*** Model 2
regress  compliance HP loco enfr rounds_open rounds_enfr, r
estat ic

*** Model 3
regress  compliance HP loco enfr loco_HP - enfr_loco, r
estat ic

*** Model 4
regress  compliance HP loco enfr rounds_open rounds_enfr loco_HP - enfr_loco, r
estat ic

*** Model 5
regress  compliance HP loco enfr loco_HP - LP_hake_rounds_enfr, r
estat ic

*** Model 6?
*regress  compliance HP loco enfr loco_HP - enfr_loco i.round, r
*estat ic

************************************************************
* Probit regression models to assess the effect of  
* treatment variables over the probability of a fisher behaving 
* as a complier
***********************************************************

** Restoring original database and preserving before collapsing
restore
preserve 


** Generating database with compliers (i.e. fishers that extract zero in all rounds)
collapse (sum) overextraction, by (id loco hake HP LP)

** Generating variable for compliers
generate complier = 0
replace complier = 1 if overextraction ==0

** Multiplicative variables for interaction terms

generate HP_loco = HP * loco 
generate HP_hake = HP * hake 
generate LP_loco = LP * loco
generate LP_hake = LP * hake 

** Probit model complier ~ treatment variabels and clustered errors by subject 

*** Model 1
probit complier HP_hake LP_loco LP_hake HP_loco, r
mfx

***********************************************************
*Probit regression models to assess the effect of treatment variables 
*over the probability of reporting aggregated by group 
***********************************************************
restore
preserve

** Generates a variable to identify observations that corresponds to an oportunity to report
generate opt_report = observer == 1 & overext_observed > 0

** Aggregating obervation to estimate probability of reporting by group and round
collapse (sum) opts_report = opt_report n_report= report (mean) mean_overext_observed= overext_observed, by(HP LP loco hake group_id round)	

** Filtering observation from open access stage
drop if round < 11

* Generating variable with probability of reporting and round adjusted
generate prob_report = n_report/opts_report
generate round_adj = round - 11

** Multiplicative variables for interaction terms

generate HP_loco = HP * loco
generate HP_hake   = HP * hake
generate LP_loco   = LP * loco
generate LP_hake   = LP * hake

*** Model 1
regress prob_report HP loco, r
estat ic 

*** Model 2
regress prob_report HP loco mean_overext_observed round_adj, r
estat ic 

*** Model 3
regress prob_report HP_loco HP_hake LP_loco LP_hake mean_overext_observed round_adj, r
estat ic 
