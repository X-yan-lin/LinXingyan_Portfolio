/*
Name: R1_dataexploration_Uganda.do
Date Created: Aug 29, 2021
Date Last Modified: SEP 7,2021
Created by: Xingyan Lin
Uses data: Round1 survey data 
Creates data: Uganda_r1.dta 
*/

clear all
set more off 
version 12.0
set trace off
cap log close
pause off

/// Survey Round 1, implemented in June 2020.

*Set paths for Round1 dataset
if "`c(username)'"=="xingyanlin"{
	global R1 "/Users/xingyanlin/Dropbox/WB Covid Phone Surveys/Uganda/UGA_2020_HFPS_v07_M_STATA12/round1"
	global clean "/Users/xingyanlin/Dropbox/WB Covid Phone Surveys/Clean Data"
}

// Prep HH-level data

* Safety Nets; long form
use "$R1/SEC10", clear
gen net="cash" if safety_net==101
replace net="food" if safety_net==102
replace net="inkind" if safety_net==103
drop safety_net__id other_nets
replace s10q02=0 if s10q01==2
replace s10q04=0 if s10q03==2
recode s10q01 2=0
recode s10q03 2=0
egen assist_since_march_ugx_=rowtotal(s10q02 s10q04) //don't distinguish source of aid
egen assist_since_march_any_=rowmax(s10q01 s10q03) //don't distinguish source of aid
drop s10q01 s10q02 s10q03 s10q04
reshape wide assist_since_march_ugx_ assist_since_march_any_, i(HHID) j(net) string
tempfile r1
save `r1', replace

* Food
use "$R1/SEC9A", clear
merge 1:1 HHID using `r1', nogen
tempfile r1
save `r1', replace

* Food security
use "$R1/SEC7", clear
merge 1:1 HHID using `r1', nogen
tempfile r1
save `r1', replace

* Income sources; note data are in long form
use "$R1/SEC6", clear
drop s6q01_Other
drop if income_loss__id==-96
gen incid="hhag" if income_loss__id==1
replace incid="hhent" if income_loss__id==2
replace incid="wage_emp" if income_loss__id==3
replace incid="unemp_ben" if income_loss__id==4
replace incid="remittances" if income_loss__id==5
replace incid="fam_assist" if income_loss__id==6
replace incid="nonfam_assist" if income_loss__id==7
replace incid="invest_save" if income_loss__id==8
replace incid="pension" if income_loss__id==9
replace incid="govt_assist" if income_loss__id==10
replace incid="charity_assist" if income_loss__id==11
drop income_loss__id s6q01 //note data on income sources (Yes/No) is captured in whether they respond about income changes
ren s6q02 inc_change_
reshape wide inc_change_, i(HHID) j(incid) string
merge 1:1 HHID using `r1', nogen
tempfile r1
save `r1', replace

* Agriculture
use "$R1/SEC5A", clear
drop s5aq22* s5aq23* s5aq24*
merge 1:1 HHID using `r1', nogen
tempfile r1
save `r1', replace

* Employment HH-level variables
use "$R1/SEC5", clear
keep HHID s5q09-s5q14
merge 1:1 HHID using `r1', nogen
tempfile r1
save `r1', replace

* Education
use "$R1/SEC4", clear
keep HHID s4q012-s4q17_Other
merge 1:1 HHID using `r1', nogen
tempfile r1
save `r1', replace

* ID of main respondent
use "$R1/interview_result", clear
keep HHID Rq09
replace Rq09=1 if missing(Rq09) //assume respondent is member 1 if not specified
tempfile r1res
save `r1res', replace // to merge with respondent-level data
ren Rq09 respid
merge 1:1 HHID using `r1', nogen
tempfile r1
save `r1', replace

* Date, geography, weights, HH IDs
use "$R1/Cover", clear
*gen datestr = substr(Sq02,1,10) //not necessary
gen double date = date(Sq02, "YMD")
format date %td
la var date "Survey date" 
*drop w1 uhps mult hmult respond wfinal datestr
drop respond Sq02
*ren Sq01 intname //why?
*save CR1_cover.dta
merge 1:1 HHID using `r1', nogen
tempfile r1
save `r1', replace


// Prep individual-level data

* Employment respondent-level variables
use "$R1/SEC5", clear
keep HHID-s5q08c
merge 1:1 HHID using `r1res', nogen
ren Rq09 hh_roster__id // get id of respondent
tempfile r1resp
save `r1resp', replace

* HH Roster
use "$R1/SEC1", clear
ren hhid HHID // good catch!
bys HHID: gen order=_n 
ta order // note two households have no roster info
drop order
merge 1:1 HHID hh_roster__id using `r1resp'
gen nomatch=_merge==2
egen nom=max(nomatch), by(HHID)
br if nom==1 // two non-matched are to HHs with no one in the roster
drop nomatch nom _merge
tempfile r1hhm
save `r1hhm', replace

// Merge to individual level

use `r1', clear
merge 1:m HHID using `r1hhm'
drop _merge
order HHID baseline_hhid BSEQNO hh_roster__id t0_ubos_pid pid_ubos respid
save "$clean/Uganda_r1", replace

**************************************************************************************************
/*
Name: UG_analysis.do
Date Created: Oct 17, 2021
Date Last Modified: DEC 12, 2021
Created by: Xingyan Lin
Uses data: Uganda_clean.dta
*/
***************************************************************************************************
clear all
set more off 
version 12.0
set trace off
cap log close
pause off

*Set paths
if "`c(username)'"=="xingyanlin"{
	global home "/Users/xingyanlin/Dropbox/WB Covid Phone Surveys"
	global clean "$home/Clean Data"
	global output "$home/Output/Uganda"
}
use "$clean/Uganda_clean.dta", clear 

//////
// Summary Statistics
//////

* to adapt for summary statistics table

local indvar hh_roster__id age sex main_respondent

local hhvar hh_head hh_age1 hh_sex1 hhsize1 new_member_hh old_member_hh resident_status relate_hhhead ag_2020 ag_2020_2 nf_hh_operating  nf_hh_lastinterview  nf_hh_revenue num_adults  num_child_0_4 num_child_5_10 num_child_11_17 food_insec num_ingrade7 

local edu att_bsclo_hh att_bsclo_ind eduact_7days edu_* num_ingrade7 grade1 

local geography districtname districtcode countyname countycode subcountyname subcountycode parishname parishcode urban_rur subreg region 

local workvar work_hour employment work_participation work_before_covid agr_eng_indi inc_change_* same_job samejob_lain bem employment_hh

local assetvar asset_* loan_*

eststo sum_indvar: quietly estpost sum `indvar', d
esttab sum_indvar using "$output/sum_indvar.csv", ///
	cells("count(fmt(0) label(N)) mean(fmt(3) label(Mean)) sd(fmt(3) label(SD)) min(fmt(1) label(Min)) p25(fmt(1) label(25th)) p50(fmt(1)label(Median)) p75(fmt(1) label(75th)) max(fmt(1) label(Max))") ///
	star(* .10 ** .05 *** .01) replace noobs nonum nomtitle label 

eststo sum_hhvar: quietly estpost sum `hhvar', d
esttab sum_hhvar using "$output/sum_hhvar.csv", ///
	cells("count(fmt(0) label(N)) mean(fmt(3) label(Mean)) sd(fmt(3) label(SD)) min(fmt(1) label(Min)) p25(fmt(1) label(25th)) p50(fmt(1)label(Median)) p75(fmt(1) label(75th)) max(fmt(1) label(Max))") ///
	star(* .10 ** .05 *** .01) replace noobs nonum nomtitle label 

eststo sum_edu: quietly estpost sum `edu', d
esttab sum_edu using "$output/sum_edu.csv", ///
	cells("count(fmt(0) label(N)) mean(fmt(3) label(Mean)) sd(fmt(3) label(SD)) min(fmt(1) label(Min)) p25(fmt(1) label(25th)) p50(fmt(1)label(Median)) p75(fmt(1) label(75th)) max(fmt(1) label(Max))") ///
	star(* .10 ** .05 *** .01) replace noobs nonum nomtitle label 

eststo sum_geo: quietly estpost sum `geography', d
esttab sum_geo using "$output/sum_geo.csv", ///
	cells("count(fmt(0) label(N)) mean(fmt(3) label(Mean)) sd(fmt(3) label(SD)) min(fmt(1) label(Min)) p25(fmt(1) label(25th)) p50(fmt(1)label(Median)) p75(fmt(1) label(75th)) max(fmt(1) label(Max))") ///
	star(* .10 ** .05 *** .01) replace noobs nonum nomtitle label 

eststo sum_em: quietly estpost sum `workvar', d
esttab sum_em using "$output/sum_em.csv", ///
	cells("count(fmt(0) label(N)) mean(fmt(3) label(Mean)) sd(fmt(3) label(SD)) min(fmt(1) label(Min)) p25(fmt(1) label(25th)) p50(fmt(1)label(Median)) p75(fmt(1) label(75th)) max(fmt(1) label(Max))") ///
	star(* .10 ** .05 *** .01) replace noobs nonum nomtitle label 

eststo sum_asset: quietly estpost sum `assetvar', d
esttab sum_asset using "$output/sum_asset.csv", ///
	cells("count(fmt(0) label(N)) mean(fmt(3) label(Mean)) sd(fmt(3) label(SD)) min(fmt(1) label(Min)) p25(fmt(1) label(25th)) p50(fmt(1)label(Median)) p75(fmt(1) label(75th)) max(fmt(1) label(Max))") ///
	star(* .10 ** .05 *** .01) replace noobs nonum nomtitle label 
eststo clear
	

//////
// Figures
//////

* Example code, means and CI for a variable over rounds by subgroup

preserve
gen schoolkids=(num_child_5_10>0 | num_child_11_17>0)
collapse (mean) workl7=work_hour (sd) sd=work_hour (count) n=work_hour, by(schoolkids round)
gen hi=workl7 + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo=workl7 - invttail(n-1,0.025)*(sd/sqrt(n))
local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)	
twoway 	(line workl7 round if schoolkids==1, color(black)) ///
		(rcap hi lo round if schoolkids==1, color(black)) ///
		(line workl7 round if schoolkids==0, color(gs8) lpattern(dash)) ///
		(rcap hi lo round if schoolkids==0, color(gs8)) ///
		, `white' ///	
		xtitle("", size(small)) ytitle("Wage work hours in last 7 days", size(small)) ///
		ylabel(, labsize(small) angle(0) nogrid) ///
		xlabel(, valuelabels labsize(small)) ///
		text(30 5 "Any schoolchildren" , color(black) size(small) placement(s)) ///
		text(37 5 "No schoolchildren" , color(gs8) size(small) placement(n)) ///
		legend(off) 
restore
graph export "$output/Line_WorkHrs_Round.pdf",replace


*School enrollment by age
preserve 
gen school_age = age if age < 18 
gen school_enrollment = . 
replace school_enrollment = 1 if grade != . 
replace school_enrollment = 0 if grade == . 
collapse (mean) school_enroll = school_enrollment, by(school_age)
local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)
twoway line school_enroll school_age, color(black) , ///
	   xtitle("", size(small)) ytitle("share of children enrolled in school before school closure", size(small)) ///
	   ylabel(, labsize(small) angle(0) nogrid) ///
	   xlabel(, valuelabels labsize(small)) ///
	   legend(off) 
restore
graph export "$output/school_enrollment_age.pdf",replace	   

*Any educational activity after school closure by round  
preserve 
collapse (mean) edu_act = edu_afsclo, by(round)
local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)
twoway line edu_act round, color(black) , ///
	   xtitle("", size(small)) ytitle("share of children in educational activities", size(small)) ///
	   ylabel(, labsize(small) angle(0) nogrid) ///
	   xlabel(, valuelabels labsize(small)) ///
	   legend(off) 
restore
graph export "$output/edu_activity_round.pdf",replace	   

*Any educational activity after school closure by grade
preserve
collapse (mean) edu_act = edu_afsclo, by(grade1)
local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)
twoway line edu_act grade1, color(black) , ///
	   xtitle("", size(small)) ytitle("share of children in educational activities", size(small)) ///
	   ylabel(, labsize(small) angle(0) nogrid) ///
	   xlabel(, valuelabels labsize(small)) ///
	   legend(off) 
restore
graph export "$output/edu_activity_grade1.pdf",replace	   

*Educational activities in last 7 days by grade 
preserve
collapse (mean) eduac_7day = eduact_7days, by(grade1 round)
local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)
twoway (line eduac_7day grade1 if round >= 4, color(black)) (line eduac_7day grade1 if round <4, color(gs8) lpattern(dash)), ///
	   xtitle("", size(small)) ytitle("share of children in educational activities in past 7 days", size(small)) ///
	   ylabel(, labsize(small) angle(0) nogrid) ///
	   xlabel(, valuelabels labsize(small)) ///
	   legend(off) 
restore
graph export "$output/edu_activity_7day_grade1.pdf",replace	   

gen grade_treat=inlist(grade1,7,11,13)
gen grade_ctl=inlist(grade1,5,6,8,9,10,12) //extending the comparison grades slightly
egen grade_treat_hh=max(grade_treat), by(hhid) //tag all households that have a child in treated grades, apply across rounds
egen grade_ctl_hh=max(grade_ctl), by(hhid) //tag all households that have a child in control grades, apply across rounds
gen reopen_part_treat=1 if grade_treat_hh==1 //treatment households
replace reopen_part_treat=0 if grade_ctl_hh==1 //control households
replace reopen_part_treat=2 if grade_treat_hh==1 & grade_ctl_hh==1 // "mixed" households

*Set treatment and control group 
tab s1cq09a if round ==4 & s1cq03 == 1

replace s1cq03 = 2 if missing(s1cq03) & !missing(s1cq09a)

*Set post / pretreament -- after oct15  
gen post = . 
replace post = 1 if round == 4 // | round == 6 |round == 5
replace post = 0 if round == 1 | round == 2 | round == 3


preserve
keep if main_respondent == 1  // only keep data for household responents 
*keep if workinghrs_l7>0
keep if !missing(grade_treat_hh) // only keep households that have non-missing values for the treatment variable 
keep if inlist(round,1,2,3,4,5,6) 
//replace wave=1 if wave==2 & monum==726 
//replace wave=2 if wave==3 & post==0
replace reopen_part_treat=1 if reopen_part_treat ==2
ta round month
su work_hour if main_respondent == 1 & round==1 & !missing(reopen_part_treat)
su work_hour if main_respondent == 1 & round ==2 & !missing(reopen_part_treat)
su work_hour if main_respondent == 1 & round ==3 & !missing(reopen_part_treat) //& workinghrs_l7>0
//su workinghrs_l7 if resp==1 & wave==1 & !missing(reopen_treat2) & workinghrs_l7>0
gen period = round
//round 1: Jun03 - Jun21; round 2 Jul27 - Aug19; round 3: Sep04 - Oct02; round 4: Oct27 - Nov17; round 5: Feb02 - Feb21; round 6: Mar02 - Apr12
lab def pd 1 "Jun" 2 "July- Aug19" 3 "Sep- Oct02" 4 "Oct 27-Nov" 5 "Feb" 6 "Mar- Apr"
la val period pd
ta period
*restore
collapse (mean) workl7=work_hour (sd) sd=work_hour (count) n=work_hour, by(reopen_part_treat period)
gen hi=workl7 + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo=workl7 - invttail(n-1,0.025)*(sd/sqrt(n))
*drop workl7	
*bys month reopen_treat2: egen workl7 = mean(workinghrs_l7)
*twoway *(line workl7 month if reopen_treat2==0, color(black)) 
*(line workl7 month if reopen_treat2==1, color(black)  lpattern(dash)), `white' 
local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)	
twoway 	(line workl7 period if reopen_part_treat==1, color(black)) ///
		(rcap hi lo period if reopen_part_treat==1, color(black)) ///
		(line workl7 period if reopen_part_treat==0, color(gs8) lpattern(dash)) ///
		(rcap hi lo period if reopen_part_treat==0, color(gs8)) ///
		, `white' ///	
		xtitle("", size(small)) ytitle("Total work hours in last 7 days", size(small)) ///
		ylabel(, labsize(small) angle(0) nogrid) ///
		xlabel(, valuelabels labsize(small)) ///
restore
graph export "$output/Line_WorkHrs_Grade_Round.pdf",replace

//identify the ag household.
gen ag_round=1 if s5bq01==1 |  s5bq01==1 | ag_2020_2==1
egen ag_hh=max(ag_round), by(hhid)
replace ag_hh=0 if missing(ag_hh)
recode work_participation 2=0
ta work_participation

egen inc_schclo_hh = max(inc_change_schclo_total_income), by(hhid)

local indvar age sex
local hhvar hh_age1 hh_sex1 num_adults num_child_0_4 num_child_5_10 num_child_11_17 ag_hh nf_hh_operating urban_rural food_insec //inc_schclo_hh
su `indvar' `hhvar' if !missing(reopen_part_treat)  & !missing(work_participation) & !missing(post)

preserve 
*gen schoolkids = (num_child_5_10 >0 | num_child_11_17 >0)
drop if region == "##N/A##"
encode region, gen(regions)
eststo r1: reghdfe work_participation i.reopen_part_treat##i.post `indvar' `hhvar', absorb(hhid i.regions##i.month) vce(cluster hhid)
        su work_participation if reopen_part_treat == 0 & e(sample)
		estadd scalar Mean = r(mean)
restore 
esttab r1 using "$output/regression.csv", ///
	scalars("Mean Dep Var ontrol Mean" "r2 R-squared") ///
	nogap star(* .10 ** .05 *** .01) b(3) se(3) nobaselevels label drop(_cons) ///
	replace se 
est clear

local indvar age sex
local hhvar hh_age1 hh_sex1 num_adults num_child_0_4 num_child_5_10 num_child_11_17 ag_hh nf_hh_operating urban_rural
su `indvar' `hhvar' if !missing(reopen_part_treat)  & !missing(work_participation) & !missing(post)

preserve 
*gen schoolkids = (num_child_5_10 >0 | num_child_11_17 >0)
drop if region == "##N/A##"
encode region, gen(regions)
eststo r1: reghdfe work_hour i.reopen_part_treat##i.post `indvar' `hhvar', absorb(hhid i.regions##i.month) vce(cluster hhid)
        su work_hour if reopen_part_treat == 0 & e(sample)
		estadd scalar Mean = r(mean)
restore 
esttab r1 using "$output/regression_workhour.csv", ///
	scalars("Mean Dep Var ontrol Mean" "r2 R-squared") ///
	nogap star(* .10 ** .05 *** .01) b(3) se(3) nobaselevels label drop(_cons) ///
	replace se 
est clear


local indvar age sex
local hhvar hh_age1 hh_sex1 num_adults num_child_0_4 num_child_5_10 num_child_11_17 ag_hh nf_hh_operating urban_rural food_insec
su `indvar' `hhvar' if !missing(reopen_part_treat)  & !missing(work_participation) & !missing(post)

preserve 

drop if region == "##N/A##"
encode region, gen(regions)

eststo r1: reghdfe employment i.reopen_part_treat##i.post `indvar' `hhvar', absorb(hhid i.regions##i.month) vce(cluster hhid)
        su employment if reopen_part_treat == 0 & e(sample)
		estadd scalar Mean = r(mean)
restore 
esttab r1 using "$output/regression_emp.csv", ///
	scalars("Mean Dep Var ontrol Mean" "r2 R-squared") ///
	nogap star(* .10 ** .05 *** .01) b(3) se(3) nobaselevels label drop(_cons) ///
	replace se 
est clear
