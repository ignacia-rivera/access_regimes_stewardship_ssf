
* Set your own working directory

use "C:\Users\Ignacia Rivera\Desktop\GitHub\access_regimes_stewardship_ssf\Data\DB_fishers_experiment.dta"

***********************************************************
* Generating new variables for analysis 
***********************************************************

** Percent of compliance for each individual in each round
g compliance = ((50 - overextraction)*100)/50

** Adjusted rounds to run models

g round_adj = .
replace round_adj = round - 1 if round < 11
replace round_adj = round - 11 if round >= 11

** Variable for non-enforced (1) and peer-enforced (2)stage

g stage = .
replace stage = 1 if round < 11
replace stage = 2 if round >= 11

label define stagelb 1 "Non-enforced" 2 "Peer-enforced"
label values stage stagelb

** Dummy variable for Loco frame 

g Loco = .
replace Loco = 1 if framing == 1
replace Loco = 0 if framing == 2

** Dummy variable for Hake frame 

g Hake = .
replace Hake = 1 if framing == 2
replace Hake = 0 if framing == 1

** Multiplicative variables for linear models

g loco_rounds = round_adj * Loco
g hake_rounds = round_adj * Hake


***********************************************************
* Linear model to test the effect of fame on compliance and 
* its erosion with clustered standard errors 
***********************************************************

local s = 1

foreach performance in 1 2 {
                 foreach stage in 1 2 {
                                  if `s' == 1 display _newline(2) "LINEAR REGRESSION OF COMPLIANCE AS A FUNCTION OF FRAME AND ROUND FRAME INTERACTION"                                                
                                  
								  if `performance' == 1  display _newline(2) "PERFORMANCE: High   Stage: `stage'"
								  if `performance' == 2  display _newline(2) "PERFORMANCE: Low   Stage: `stage'"
								  
								  regress compliance ib2.framing loco_rounds hake_rounds if performance == `performance' & stage ==`stage', vce(cluster  group_id) 
                                 
                               
                             local s = `s' + 1
                         }
               }
 

 ***********************************************************
* Probit regression models to assess the effect of the 
*frame of the game over the probability of fishers behaving 
*as compliers 
***********************************************************

* Preserving original database before collapsing
preserve

* Generating database with compliers (i.e. fishers that extract zero in each round.
collapse (sum) overextraction, by (id  Loco performance stage group_id)

* Generating variable for compliers

g complier = 0
replace complier = 1 if overextraction ==0


foreach performance in 1 2 {
                 foreach stage in 1 2 {
                                  if `s' == 2 display _newline(2) "PROBIT OF COMPLIER BEHAVIOR AS A FUNCTION OF FRAME"                                                
                                  
								  if `performance' == 1  display _newline(2) "PERFORMANCE: High   Stage: `stage'"
								  if `performance' == 2  display _newline(2) "PERFORMANCE: Low   Stage: `stage'"
								  
								  probit complier ib0.Loco if performance == `performance' & stage == `stage', vce(cluster group_id)
                               
                             local s = `s' + 1
                         }
               }

***********************************************************
*Probit regression models to assess the effect of the 
*frame of the game over the probability of reporting an 
*infraction
***********************************************************

* Restoring to original database

restore

* Running probit model for each type of association 

foreach performance in 1 2 {
                                  if `s' == 3 display _newline(2) "PROBIT OF REPORTING AS A FUNCTION OF FRAME AND OBSERVED OVERHARVEST"                                                
                                  
								  if `performance' == 1  display _newline(2) "PERFORMANCE: High "
								  if `performance' == 2  display _newline(2) "PERFORMANCE: Low "
								  
								  probit report ib0.Loco overext_observed  round_adj if performance == `performance' & overext_observed >0 , vce(cluster group_id)
                               
                             local s = `s' + 1
							 
                         }
               
***********************************************************
* Estimating 95% CI for compliance figures
***********************************************************

regress compliance round_adj if performance == 1 & framing == 1 & stage ==1, vce(cluster  group_id)
