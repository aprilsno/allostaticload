*********************************************************************
*  Assignment:    Final Project                                        
*                                                                    
*  Description:   Replicate findings from SWAN AL paper
*
*  Name:          Sara O'Brien
*
*  Date:          5/8/23                                       
*------------------------------------------------------------------- 
*  Job name:      finalproject_saraob.sas   
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         SWAN stc datasets
*
*  Output:        PDF, RTF files    
*                                                                    
********************************************************************;

* Set macros for librefs;
%LET data=/home/u49497589/BIOS669/Final Project/Data;

proc printto log="/home/u49497589/BIOS669/Final Project/finaproject_saraob.log" new; run;

* Create permanent lib to store data;
libname data "&data";

* Import stc files;
proc cimport infile="&data/28762-0001-Data.stc" lib=work; run;
proc cimport infile="&data/29221-0001-Data.stc" lib=work; run;
proc cimport infile="&data/29401-0001-Data.stc" lib=work; run;
proc cimport infile="&data/29701-0001-Data.stc" lib=work; run;
proc cimport infile="&data/30142-0001-Data.stc" lib=work; run;
proc cimport infile="&data/30501-0001-Data.stc" lib=work; run;
proc cimport infile="&data/31181-0001-Data.stc" lib=work; run;
proc cimport infile="&data/31901-0001-Data.stc" lib=work; run;
proc cimport infile="&data/32122-0001-Data.stc" lib=work; run;
proc cimport infile="&data/32721-0001-Data.stc" lib=work; run;
proc cimport infile="&data/32961-0001-Data.stc" lib=work; run;

* Create permanent datasets;
%macro create(dsn=,ref=);
data data.&dsn;
	set &ref;
run;
%mend;

%create(dsn=baseline,ref=DA28762P1);
%create(dsn=visit1,ref=DA29221P1);
%create(dsn=visit2,ref=DA29401P1);
%create(dsn=visit3,ref=DA29701P1);
%create(dsn=visit4,ref=DA30142P1);
%create(dsn=visit5,ref=DA30501P1);
%create(dsn=visit6,ref=DA31181P1);
%create(dsn=visit7,ref=DA31901P1);
%create(dsn=visit8,ref=DA32122P1);
%create(dsn=visit9,ref=DA32721P1);
%create(dsn=visit10,ref=DA32961P1);
 
* Create sets of eligible cases only;
%macro eligible(vname=,vnumber=);

data alds&vnumber;
	set data.&vname (keep=SWANID STATUS&vnumber SYSBP1&vnumber DIABP1&vnumber CRPRESU&vnumber HDLRESU&vnumber CHOLRES&vnumber BMI&vnumber WAIST&vnumber HIP&vnumber GLUCRES&vnumber TRIGRES&vnumber DHAS&vnumber);
	if ^missing(SYSBP1&vnumber) and ^missing(DIABP1&vnumber) and ^missing(CRPRESU&vnumber) and ^missing(HDLRESU&vnumber) and ^missing(CHOLRES&vnumber) and ^missing(BMI&vnumber) and ^missing(GLUCRES&vnumber) and ^missing(TRIGRES&vnumber) and ^missing(DHAS&vnumber) and ^missing(WAIST&vnumber) and ^missing(HIP&vnumber);
	WHRATIO&vnumber = WAIST&vnumber / HIP&vnumber;
	alscore&vnumber = 0; * This is temporary to check which participants will have an al score at ≥2 follow-up visits;
run;

%mend;

%eligible(vname=baseline,vnumber=0);
%eligible(vname=visit1,vnumber=1);
%eligible(vname=visit3,vnumber=3);
%eligible(vname=visit4,vnumber=4);
%eligible(vname=visit5,vnumber=5);
%eligible(vname=visit6,vnumber=6);
%eligible(vname=visit7,vnumber=7);

* Merge eligible datasets;
data aldsmerge;
	merge alds0 (in=base) alds1 alds3 alds4 alds5 alds6 alds7;
	by swanid;
	if base and ^missing(status0) and status0 ^= 6 and
		sum(^missing(alscore1),^missing(alscore3),^missing(alscore4),^missing(alscore5),^missing(alscore6),^missing(alscore7)) >= 2;
run;

* Find quantile cut-off values at baseline for eligibles and write to macro vars;
ods exclude all;
proc univariate data=aldsmerge;
	var SYSBP10 DIABP10 CRPRESU0 HDLRESU0 CHOLRES0 BMI0 GLUCRES0 TRIGRES0 DHAS0 WHRATIO0;
	ods output basicmeasures=basestats quantiles=basequantiles;
run;
ods exclude none;

data _null_;
	set basequantiles;
	if varname ^= "HDLRESU0" and varname ^= "DHAS0" then do;
		%let var = varname;
		if quantile =  "75% Q3" then call symputx(&var,estimate);
	end;
	else if varname = "HDLRESU0" or varname = "DHAS0" then do;
		%let var = varname;
		if quantile = "25% Q1" then call symputx(&var,estimate);
	end;
run;

* Calculate al score at each visit on final analytic;
%macro alcalc(vnumber=);

data alscore&vnumber;
	set alds&vnumber;
	if SYSBP1&vnumber > &SYSBP10 then alscore&vnumber = alscore&vnumber + 1;
	if DIABP1&vnumber >= &DIABP10 then alscore&vnumber = alscore&vnumber + 1;
	if CRPRESU&vnumber >= &CRPRESU0 then alscore&vnumber = alscore&vnumber + 1;
	if HDLRESU&vnumber <= &HDLRESU0 then alscore&vnumber = alscore&vnumber + 1;
	if CHOLRES&vnumber >= &CHOLRES0 then alscore&vnumber = alscore&vnumber + 1;
	if BMI&vnumber >= &BMI0 then alscore&vnumber = alscore&vnumber + 1;
	if GLUCRES&vnumber >= &GLUCRES0 then alscore&vnumber = alscore&vnumber + 1;
	if TRIGRES&vnumber >= &TRIGRES0 then alscore&vnumber = alscore&vnumber + 1;
	if DHAS&vnumber <= &DHAS0 then alscore&vnumber = alscore&vnumber + 1;
	if WHRATIO&vnumber >= &WHRATIO0 then alscore&vnumber = alscore&vnumber + 1;
run;

%mend;

%alcalc(vnumber=0);
%alcalc(vnumber=1);
%alcalc(vnumber=3);
%alcalc(vnumber=4);
%alcalc(vnumber=5);
%alcalc(vnumber=6);
%alcalc(vnumber=7);

* Create final analytic dataset;
data finalanalytic;
	merge alscore0 (in=base) alscore1 alscore3 alscore4 alscore5 alscore6 alscore7;
	by swanid;
	if base and ^missing(status0) and status0 ^= 6 and
		sum(^missing(alscore1),^missing(alscore3),^missing(alscore4),^missing(alscore5),^missing(alscore6),^missing(alscore7)) >= 2; 
run;

* Check derived variables;
proc freq data=finalanalytic;
	title 'Check that AL scores across visits are all within expected range';
	tables alscore0 alscore1 alscore3 alscore4 alscore5 alscore6 alscore7 / missing list;
run;

data checkal;
	set finalanalytic;
	 SYSBP10check=126;
	 DIABP10check=80;
	 CRPRESU0check=4.200;
	 HDLRESU0check=46;
	 CHOLRES0check=213;
	 BMI0check=31.7052;
	 WHRATIO0check=0.842809;
	 GLUCRES0check=98.0;
	 TRIGRES0check=128;
	 DHAS0check=77.000;
run;

proc print data=checkal (obs=20);
	var swanid alscore0 SYSBP10 SYSBP10check DIABP10 DIABP10check CRPRESU0 CRPRESU0check HDLRESU0 HDLRESU0check
	CHOLRES0 CHOLRES0check BMI0 BMI0check WHRATIO0 WHRATIO0check GLUCRES0 GLUCRES0check 
	TRIGRES0 TRIGRES0check DHAS0 DHAS0check;
	where alscore0>0;
run;

* Create table 1;
ods exclude all;
proc univariate data=finalanalytic;
	var SYSBP10 DIABP10 CRPRESU0 HDLRESU0 CHOLRES0 BMI0 GLUCRES0 TRIGRES0 DHAS0 WHRATIO0 ALSCORE0;
	ods output basicmeasures=basestats2 quantiles=basequantiles2;
run;
ods exclude none;

proc sort data=basestats2; by varname; run;
proc sort data=basequantiles2; by varname; run;

data basestats2;
	set basestats2 (rename=(locvalue=mean varvalue=std));
	if varmeasure='Std Deviation';
	keep varname mean std;
run;

data basequantiles2;
	set basequantiles2;
	if quantile="100% Max" or quantile="50% Median" or quantile="0% Min";
run;

proc transpose data=basequantiles2 out=quantrans2; by varname; run;

data table1;
	merge quantrans2 (rename=(col1=max col2=med col3=min) drop=_name_ _label_) basestats2;
	by varname;
	minabr = put(min,6.2);
	maxabr = put(max,6.2);
	stdv = put(std,6.2);
	avg = put(mean,6.2);
	fiftyqt = put(med,6.2);
	minmax = cat(minabr,"-",strip(maxabr));
	if varname = "BMI0" then do; temp=5; cutoff=cat("≥",put(strip(&BMI0),5.2)); end;
	if varname = "CHOLRES0" then do; temp=3; cutoff=cat("≥",put(strip(&CHOLRES0),10.)); end;
	if varname = "CRPRESU0" then do; temp=9; cutoff=cat("≥",put(strip(&CRPRESU0),6.2)); end;
	if varname = "DHAS0" then do; temp=10; cutoff=cat('≤',put(strip(&DHAS0),6.2)); end;
	if varname = "DIABP10" then do; temp=2; cutoff=cat("≥",put(strip(&DIABP10),6.2)); end;
	if varname = "GLUCRES0" then do; temp=7; cutoff=cat("≥",put(strip(&GLUCRES0),6.2)); end;
	if varname = "HDLRESU0" then do; temp=4; cutoff=cat("≤",put(strip(&HDLRESU0),6.2)); end;
	if varname = "SYSBP10" then do; temp=1; cutoff=cat("≥",put(strip(&SYSBP10),6.2)); end;
	if varname = "TRIGRES0" then do; temp=8; cutoff=cat("≥",put(strip(&TRIGRES0),6.2)); end;
	if varname = "WHRATIO0" then do; temp=6; cutoff=cat("≥",put(strip(&WHRATIO0),4.2)); end;
	if varname = "alscore0" then do; temp=11; end;
	drop max med min mean std minabr maxabr;
run;

data tablelabels ;
	length varname $20;
	input varname $ temp;
	datalines;
Cardiovascular 0.5
Metabolic 2.5
Inflammatory 8.5
Neuroendocrine 9.5
;

proc sort data=table1; by varname; run;
proc sort data=tablelabels; by varname; run;

data table1final; length varname $20; merge table1 tablelabels; by varname; run;

proc sort data=table1final; by temp; run;

proc format;
	value $varnamelabel
		'SYSBP10' = 'Systolic blood pressure (mm Hg)'
		'DIABP10' = 'Diastolic blood pressure (mm Hg)'
		'CHOLRES0' = 'Total cholesterol (mg/dL)'
		'HDLRESU0' = 'HDL (mg/dL)'
		'BMI0' = 'BMI (kg/m2)'
		'WHRATIO0' = 'WHR'
		'GLUCRES0' = 'Glucose (mg/dL)'
		'TRIGRES0' = 'Triglycerides (mg/dL)'
		'CRPRESU0' = 'CRP (mg/L)'
		'DHAS0' = 'DHEA-S (μg/dL)'
		'alscore0' = 'AL';
run;

proc report data=table1final;
	title 'Table 1. Biomarker and AL Distribution at Baseline, SWAN (n = 2,320)';
	columns varname avg fiftyqt minmax stdv cutoff;
	define varname / ' ' format = $varnamelabel.;
	define avg / 'Mean';
	define fiftyqt / 'Median';
	define minmax / 'Range';
	define stdv / 'SD';
	define cutoff / 'Quartile Cutoff Value';
	compute varname;
		if varname='Cardiovascular' or varname='Metabolic' or varname='Inflammatory' or varname='Neuroendocrine' then do;
			call define(_row_,"style", "style=[font_weight=bold]");
		end;
	endcomp; 
	footnote "Abbreviations: AL, allostatic load; BMI, body mass index; CRP, C-reactive protein; DHEA-S, dehydroepiandrosterone; HDL, high-density lipoprotein cholesterol; SD, standard deviation; SWAN, Study of Women's Health Across the Nation; WHR, waist-to-hip ratio.";
run;

* Create figure 1;
ods exclude all;
proc means data=finalanalytic mean clm alpha=0.05; var ALSCORE0; ods output summary=mean0; run;
proc means data=finalanalytic mean clm alpha=0.05; var ALSCORE1; ods output summary=mean1; run;
proc means data=finalanalytic mean clm alpha=0.05; var ALSCORE3; ods output summary=mean3; run;
proc means data=finalanalytic mean clm alpha=0.05; var ALSCORE4; ods output summary=mean4; run;
proc means data=finalanalytic mean clm alpha=0.05; var ALSCORE5; ods output summary=mean5; run;
proc means data=finalanalytic mean clm alpha=0.05; var ALSCORE6; ods output summary=mean6; run;
proc means data=finalanalytic mean clm alpha=0.05; var ALSCORE7; ods output summary=mean7; run;
ods exclude none;

data mean0; set mean0; visit=0; mean=alscore0_mean; upper=alscore0_uclm; lower=alscore0_lclm; keep visit mean upper lower; run;
data mean1; set mean1; visit=1; mean=alscore1_mean; upper=alscore1_uclm; lower=alscore1_lclm; keep visit mean upper lower; run;
data mean3; set mean3; visit=3; mean=alscore3_mean; upper=alscore3_uclm; lower=alscore3_lclm; keep visit mean upper lower; run;
data mean4; set mean4; visit=4; mean=alscore4_mean; upper=alscore4_uclm; lower=alscore4_lclm; keep visit mean upper lower; run;
data mean5; set mean5; visit=5; mean=alscore5_mean; upper=alscore5_uclm; lower=alscore5_lclm; keep visit mean upper lower; run;
data mean6; set mean6; visit=6; mean=alscore6_mean; upper=alscore6_uclm; lower=alscore6_lclm; keep visit mean upper lower; run;
data mean7; set mean7; visit=7; mean=alscore7_mean; upper=alscore7_uclm; lower=alscore7_lclm; keep visit mean upper lower; run;
data meanal; set mean0 mean1 mean3 mean4 mean5 mean6 mean7; meanabr = put(mean,5.2); run;

proc sgplot data=meanal NOAUTOLEGEND;
	title "Figure 1. Mean allostatic load by wave, Study of Women's Health Across the Nation (SWAN).";
	vbarparm category=visit response=mean / fillattrs=(color=lightgrey) datalabel=meanabr datalabelpos=bottom;
	highlow x=visit low=lower high=upper/ HIGHCAP=SERIF LOWCAP=SERIF lineattrs=(color=black);
	yaxis label='Mean Allostatic Load' values=(2.2 to 3.1 by 0.1);
	xaxis label='Follow-up visit';
	footnote "Allostatic load score was based on systolic and diastolic blood pressure, C-reactive protein, high-density lipoprotein (HDL) cholesterol, total cholesterol, body mass index, waist-hip ratio, fasting serum glucose, triglycerides, and dehydroepiandrosterone (DHEA-S) values. Values equal or greater than the 75th percentile were defined as high risk for all biomarkers, except for HDL and DHEA-S, which values equal or lesser than the 25th percentile defined as high risk.";
run;

* Create final visualization - mean AL score by race across waves;
proc sql;
	create table raceal as
	select a.*, b.race
	from finalanalytic as a
		left join data.baseline as b
		on a.swanid=b.swanid;
quit;

proc sort data=raceal; by race; run;
proc means data=raceal mean clm alpha=0.05; var ALSCORE0; by race; ods output summary=meanrace0; run;
proc means data=raceal mean clm alpha=0.05; var ALSCORE1; by race; ods output summary=meanrace1; run;
proc means data=raceal mean clm alpha=0.05; var ALSCORE3; by race; ods output summary=meanrace3; run;
proc means data=raceal mean clm alpha=0.05; var ALSCORE4; by race; ods output summary=meanrace4; run;
proc means data=raceal mean clm alpha=0.05; var ALSCORE5; by race; ods output summary=meanrace5; run;
proc means data=raceal mean clm alpha=0.05; var ALSCORE6; by race; ods output summary=meanrace6; run;
proc means data=raceal mean clm alpha=0.05; var ALSCORE7; by race; ods output summary=meanrace7; run;

data meanrace0; set meanrace0; visit=0; mean=alscore0_mean; upper=alscore0_uclm; lower=alscore0_lclm; keep visit race mean upper lower; run;
data meanrace1; set meanrace1; visit=1; mean=alscore1_mean; upper=alscore1_uclm; lower=alscore1_lclm; keep visit race mean upper lower; run;
data meanrace3; set meanrace3; visit=3; mean=alscore3_mean; upper=alscore3_uclm; lower=alscore3_lclm; keep visit race mean upper lower; run;
data meanrace4; set meanrace4; visit=4; mean=alscore4_mean; upper=alscore4_uclm; lower=alscore4_lclm; keep visit race mean upper lower; run;
data meanrace5; set meanrace5; visit=5; mean=alscore5_mean; upper=alscore5_uclm; lower=alscore5_lclm; keep visit race mean upper lower; run;
data meanrace6; set meanrace6; visit=6; mean=alscore6_mean; upper=alscore6_uclm; lower=alscore6_lclm; keep visit race mean upper lower; run;
data meanrace7; set meanrace7; visit=7; mean=alscore7_mean; upper=alscore7_uclm; lower=alscore7_lclm; keep visit race mean upper lower; run;
data meanraceal; set meanrace0 meanrace1 meanrace3 meanrace4 meanrace5 meanrace6 meanrace7; meanabr = put(mean,5.2); run;

proc format;
	value racelabel
		1='Black'
		2='Chinese'
		3='Japanese'
		4='White'
		5='Hispanic';
run;

data meanraceal; set meanraceal; format race racelabel.; run;
		
proc sgpanel data=meanraceal NOAUTOLEGEND;
	title "Figure 2. Mean allostatic load by wave and race, Study of Women's Health Across the Nation (SWAN).";
	panelby race;
	vbarparm category=visit response=mean / fillattrs=(color=lightgrey);
	highlow x=visit low=lower high=upper/ HIGHCAP=SERIF LOWCAP=SERIF lineattrs=(color=black);
	rowaxis label='Mean Allostatic Load' ;
	colaxis label='Follow-up visit';
run;
