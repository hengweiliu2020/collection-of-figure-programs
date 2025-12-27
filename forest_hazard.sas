options sasautos=("S:\Global macros");


libname adam "S:\DEV\CSR\data\adam";
libname sdtm "S:\DEV\CSR\data\sdtm";

** this program creates the forest plot; 

data adtte; set adam.adtte;
where paramcd='PFS'  and ittfl='Y';
dose01pc=compbl(dose01p||' mg');
if dose01p=320 then trt=0;
else if dose01p=400 then trt=1; 
run;


%macro hr(indata=, outdata=, classvar=);


proc sort data=&indata out=_&indata; by &classvar; 

ods output parameterestimates=work.parmest;
proc phreg data=_&indata;
by &classvar; 
class trt;
model aval*cnsr(1)=trt/rl=pl;
run;

proc sql;
create table numpat as 
select distinct &classvar, trt,  count(distinct usubjid) as p from _&indata group by &classvar, trt; 
create table numevnt as 
select distinct &classvar, trt, count(distinct usubjid) as e from _&indata where cnsr=0 group by &classvar, trt; 

proc transpose data=numpat out=out1 prefix=p;
var p;
by &classvar;
id trt;

proc transpose data=numevnt out=out2 prefix=e;
var e;
by &classvar;
id trt;
run;

data &outdata;
merge out1 out2 parmest(in=a);
by &classvar;
if a;
run;

** get the final dataset; 
data &outdata; *(keep=subgroup trt1 trt2 hr pvalue indentweight); 
set &outdata;
pvalue=probchisq;
hr=put(hazardratio,5.2)||'('||put(hrlowerplcl,5.2)||'-'||put(hrupperplcl,5.2)||')'; 
if hazardratio<.z then hr='NE(NE-NE)';
if e1<.z then e1=0; 
if e0<.z then e0=0;
trt1=compress(p1||'('||e1||')');
trt2=compress(p0||'('||e0||')');
indentweight=2;
subgroup=&classvar;
run;

data addit; 
subgroup="&classvar";
indentweight=1; 

data &outdata; 
length subgroup $40.; 
set addit &outdata; 
run;


%mend;

%hr(indata=adtte, outdata=o1, classvar=sex);
%hr(indata=adtte, outdata=o2, classvar=agegr1);
%hr(indata=adtte, outdata=o3, classvar=race);
%hr(indata=adtte, outdata=o4, classvar=ethnic);



data forest; set o1 o2 o3 o4;
obsid=_n_;
run;

goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial' ;  
options nobyline nodate nonumber;
ods escapechar="~";
options nonumber nodate orientation = landscape;
ods graphics / height=3in width=7in noborder;
ods rtf file="S:\Global macros\figures\forest_hazard.rtf" nogtitle nogfootnote;
Proc sgplot data=forest nowall noborder nocycleattrs noautolegend;
styleattrs axisextent=data;

highlow y=obsid low=hrlowerplcl high=hrupperplcl; 
	scatter y=obsid x=hazardratio / markerattrs=(symbol=squarefilled);
	scatter y=obsid x=hazardratio / markerattrs=(size=0) x2axis;

refline 1 / axis=x label;
yaxistable subgroup / location=inside position=left labelattrs=(size=8) valuehalign=left indentweight=indentweight;
yaxistable  trt2 trt1 hr pvalue / location=inside position=right labelattrs=(size=8) valueattrs=(size=8) nomissingchar;
yaxis reverse display=none colorbands=odd colorbandsattrs=(transparency=1) offsetmin=0.08;
xaxis label='<-- Favors 400 mg    --> Favors 320 mg' values=(-40 to 40 by 20) ;
x2axis label='HR (95% CI)' display=(noline noticks novalues) labelattrs=(size=8) ;
label hr = 'Hazard Ratio (95% CI)' resp = '#CR/PR' trt2='Patients (Events) 320 mg' trt1='Patients (Events) 400 mg';


title1 font='Arial' height=0.7 j=left "Hengrui USA"  j=right "Page ~{pageof}";
title2 font='Arial' height=0.7 j=left "Protocol: SHRUS1001" j=right "Program name: forest_hazard.sas";
title3 font='Arial' height=0.7 j=left "CSR" ;
title4 font='Arial' height=0.7 j=center "Figure 14.2.2.2.8";
title5 font='Arial' height=0.7 j=center "Forest Plot for Hazard Ratios for PFS"; 
title6 font='Arial' height=0.7 j=center "ITT Population";

footnote1 justify=l "~R'\brdrt\brdrs\brdrw5'";



run;
ods rtf close;




































