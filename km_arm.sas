
options sasautos=("S:\Global macros");


libname adam "S:\DEV\CSR\data\adam";
libname sdtm "S:\DEV\CSR\data\sdtm";


%let protocol=SHRUS1001;
%let timepoint=CSR;

proc sql noprint;
select count(distinct usubjid) into :n1 -:n2 from adam.adsl 
where ittfl='Y' and tr01pg1 in ('Part 1','Part 2')
group by dose01p;

data adtte; set adam.adtte;
where paramcd='PFS'  and ittfl='Y';
dose01pc=compbl(dose01p||' mg');
run;

ods graphics on ;
ods output Survivalplot=work.SurvivalPlot quartiles=quart;

proc lifetest data=adtte plots=survival(cl test atrisk(outside(0.15))=0 to 84 by 4) ;
time aval*cnsr(1); * 1 is for censored patients;
strata dose01pc;
run;


proc sql;
create table events as 
select distinct dose01p, count(*) as n from adtte where cnsr=0
group by dose01p; 
create table censored as 
select distinct dose01p, count(*) as n from adtte where cnsr=1
group by dose01p; 

proc print data=events;
proc print data=censored;
run;

ods output parameterestimates=work.parmest;
proc phreg data=adtte;
class dose01pc;
model aval*cnsr(1)=dose01pc/rl=pl;
run;



ods graphics off;

** get the number of patients at risk ** ;

proc sort data=survivalplot out=atrisk1; by stratumnum time; where tatrisk>.z;

proc sql noprint;
select max(time) into :xmax from atrisk1 ;
run;

** create the annotation datasets  ** ;

data anno0; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='graphpercent'; textsize=8; textweight='normal'; width=20; 
label="Patients still at risk:";
y1=15; x1=0; 

data anno1; length function x1space y1space $13.; 
set atrisk1; 
where stratumnum=1;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='graphpercent'; textsize=8; textweight='normal'; width=20; 
textcolor='blue';
label=put(atrisk, 2.0);
y1=10; x1=time; 
if label<.z then delete;

data anno2; length function x1space y1space $13.; 
set atrisk1; 
where stratumnum=2;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='graphpercent'; textsize=8; textweight='normal'; width=20; 
textcolor='red';
label=put(atrisk, 2.0);
y1=5; x1=time; 
if label<.z then delete;

data anno3; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="320 mg   &n1";
y1=0.64; x1=36; 

data anno4; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="400 mg   &n2";
y1=0.6; x1=36; 


data anno14(drop=stratum); length function x1space y1space $13.; 
set quart; where stratum=1 and percent=50;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label=compbl(round(estimate,0.001)||'('||round(lowerlimit,0.001)||','||round(upperlimit,0.001)||')');
if upperlimit<.z then do;
label=compbl(round(estimate,0.001)||'('||round(lowerlimit,0.001)||','||' NE)');
end;
y1=0.64; x1=70; 

data anno15(drop=stratum); length function x1space y1space $13.; 
set quart; where stratum=2 and percent=50;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label=compbl(round(estimate,0.001)||'('||round(lowerlimit,0.001)||','||round(upperlimit,0.001)||')');
y1=0.6; x1=70; 


data anno16; length function x1space y1space $13.; 
set events; where dose01p=320;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label=put(n, best.);
y1=0.64; x1=45; 

data anno17; length function x1space y1space $13.; 
set events; where dose01p=400;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label=put(n, best.);
y1=0.6; x1=45; 


data anno18; length function x1space y1space $13.; 
set censored; where dose01p=320;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label=put(n, best.);
y1=0.64; x1=55; 

data anno19; length function x1space y1space $13.; 
set censored; where dose01p=400;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label=put(n, best.);
y1=0.6; x1=55; 


data anno5; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="HR = ";
y1=0.8; x1=36; 

data anno6; length function x1space y1space $13. label $50.;; 
set parmest;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=40; 
label=round(hazardratio, 0.001)||'(95% CI:'||compbl(round(hrlowerplcl, 0.001)||', '||round(hrupperplcl,0.001))||')';
y1=0.8; x1=45; 

data anno7; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="p = ";
y1=0.76; x1=36; 

data anno8; length function x1space y1space $13.; 
set parmest;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label=round(probchisq, 0.0001);
y1=0.76; x1=42; 


data anno9; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="CI";
y1=0.72; x1=58; 

data anno10; length function x1space y1space $13.; 
set parmest;
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label=compbl(round(hrlowerplcl, 0.001)||', '||round(hrupperplcl,0.001));
y1=0.72; x1=65; 

data anno11; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="Median (CI)";
y1=0.68; x1=58; 

data anno12; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="320 mg";
y1=0.68; x1=65; 


data anno13; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="400 mg";
y1=0.64; x1=65; 


data anno20; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="Subjects (N)";
y1=0.68; x1=40; 

data anno21; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="Events";
y1=0.68; x1=48; 

data anno22; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="Censored";
y1=0.68; x1=55; 

data anno23; length function x1space y1space $13.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='datavalue'; y1space='datavalue'; textsize=8; textweight='normal'; width=20; 
label="Median Survival (95% CI)";
y1=0.68; x1=70; 

data anno; 
length label $50.;
set anno0 anno1 anno2 anno3 anno4 anno5 anno6 anno7 anno8 anno14 anno15 anno16 anno17 anno18 anno19 anno20 anno21 anno22 anno23;
run;

** ready to do the plot ** ;

options orientation=landscape mprint mlogic symbolgen;
goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial' ;  
ods graphics /reset=all border=off width=850px height=550px;
options nobyline nodate nonumber;
ods escapechar="~";
ods rtf file="S:\Global macros\figures\km.rtf"  nogtitle nogfootnote;

proc sgplot data=survivalplot noautolegend pad=(bottom=20%) sganno=anno;
   step x=time y=survival/group=stratum legendlabel='Dose' name='Dose' ;
   xaxis label='Time (Weeks)' values=(0 to 84 by 4);
   yaxis label='Progression-Free Survival Probability';

   scatter x=time y=censored/markerattrs=(symbol=plus size=7 color=black) legendlabel='Censor' name='Censor';
   keylegend 'Censor' "Dose" /location=inside position=topright across=3 noborder;

title1 font='Arial' height=0.7 j=left "Hengrui USA"  j=right "Page ~{pageof}";
title2 font='Arial' height=0.7 j=left "Protocol: XXXXXXXXXX" j=right "Program name: km_arm.sas";
title3 font='Arial' height=0.7 j=left "CSR" ;
title4 font='Arial' height=0.7 j=center "Figure 14.2.2.1.1 Kaplan-Meier Plot of Progression-Free Survival";
title5 font='Arial' height=0.7 j=center "ITT Population";

footnote1  "~R/RTF'\brdrt\brdrs '  ";
footnote2 font='Arial' height=0.7 j=left "adam.adtte";
run;

ods rtf close;
