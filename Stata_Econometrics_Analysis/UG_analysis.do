/*
Name: UG_analysis.do
Date Created: Oct 17, 2021
Date Last Modified: Oct 17, 2021
Created by: Xingyan Lin
Last modified by: Pierre Biscaye
Uses data: Uganda_clean.dta

*/

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
if "`c(username)'"=="pierrebiscaye"{
	global home "/Users/pierrebiscaye/Dropbox/WB Covid Phone Surveys"
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


*School enrollment by age //I apply the grade value into all rounds 
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
//Think about making sperate analysis for before and after school closure 
//R4 is after the partial school closure on Oct 15 
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

//Graphs needed 
//Kenya COVID-19 cases, pandemic policy, and data collection timeline (not stata)
//no data on how much time for childcare 
//School enrollment rates by age before school closures
//Impact of treatment on household agricultural earnings in the last 14 days, by time

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

//treated in child in grade P7, S4, or S6
// control if child in grade P6 (why not S1 also?), S3, or S5
// note that if we wanted to condition on being in school or not, to focus on the partial reopening we should also condition on round 4
//gen treatment = .
//replace treatment = 1 if  s1cq09a == 16 & s1cq03 == 1 
//replace treatment = 1 if  s1cq09a == 35 & s1cq03 == 1
//replace treatment = 1 if  s1cq09a == 33 & s1cq03 == 1

//replace treatment = 0 if  s1cq09a == 15 & s1cq03 == 2
//replace treatment = 0 if  s1cq09a== 34 & s1cq03 == 2
//replace treatment = 0 if  s1cq09a == 32 & s1cq03 == 2
//egen treat = max(treatment), by(hhid hh_roster__id) //this defines treatment at the individual level, but we want treatment to be defined at the household level

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
		//xline(2.5, lcolor(red)) xline(0.5, lcolor(red)) xline(3.5, lcolor(red))  ///
		//text(34 0.5 "Onset of pandemic," "schools close" , color(black) size(small) placement(e)) ///
		//text(34 2.5 "Schools partially" "reopen" , color(black) size(small) placement(e)) ///
		//text(34 3.5 "Schools fully" "reopen" , color(black) size(small) placement(e)) ///
		//text(25 0.6 "Treatment" , color(black) size(small) placement(e)) ///
		//text(25 0.4 "Control" , color(gs8) size(small) placement(w)) ///
		//legend(off) 
restore
graph export "$output/Line_WorkHrs_Grade_Round.pdf",replace



* Example code for regression with fixed effects and some controls
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
*gen schoolkids = (num_child_5_10 >0 | num_child_11_17 >0)
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
