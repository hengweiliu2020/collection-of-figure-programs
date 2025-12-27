options sasautos=("S:\Global macros");


libname adam "S:\DEV\CSR\data\adam";
libname sdtm "S:\DEV\CSR\data\sdtm";

** this program creates the forest plot; 


data adrs; set adam.adrs; where tr01pg1='Part 2' and paramcd='CBOR' and ittfl='Y';

proc sql;

select distinct sex from adrs; 
select distinct agegr1 from adrs; 
select distinct race from adrs;
select distinct ethnic from adrs;

%macro orr(indata=, outdata=, classvar=);

proc sql;
create table tot as 
select distinct &classvar, count(distinct usubjid) as numsubj 
from &indata
group by &classvar;  

data _&indata; set &indata;
if avalc in ('PR','CR') then cat='0';
else cat='1';

proc sort data=_&indata; by &classvar; 

proc freq data=_&indata ;
by &classvar;
table cat/out=out1;
run;

proc sql noprint;
create table fram as 
select distinct &classvar from out1;

data fram; set fram;
cat='0'; output;
cat='1'; output;
run;

data out1;
merge out1 fram;
by &classvar cat;
if count<.z then do;
count=0;
percent=0;
end; 
run;

ods output binomial=bino;
proc freq data=out1;
by &classvar;
table cat/binomial;
exact binomial;
weight count/zeroes;
run;

data bino1; set bino; 
lower=round(100*nvalue1,0.1);
where name1 in ('XL_BIN');

data bino2; set bino; 
upper=round(100*nvalue1,0.1);
where name1 in ('XU_BIN');

data bino3;
merge bino1 bino2;
by &classvar;
run;

proc print data=out1;

** combine the datasets together; 
data out1; set out1; 
if cat='0'; 
resp=put(count,2.0); 
orr=round(percent,0.1); 

proc print data=tot;
proc print data=bino3;


data combine(Keep=indentweight subgroup numsubj resp orr lower upper);
merge tot out1 bino3;
by &classvar; 
subgroup=&classvar; 
indentweight=2; 
run;

data addit; 
subgroup="&classvar";
indentweight=1; 

data &outdata; 
length subgroup $40.; 
set addit combine; 
run;

%mend;
%orr(indata=adrs, outdata=forest1, classvar=sex); 
%orr(indata=adrs, outdata=forest2, classvar=agegr1); 
%orr(indata=adrs, outdata=forest3, classvar=race); 
%orr(indata=adrs, outdata=forest4, classvar=ethnic); 



data forest; set forest1 forest2 forest3 forest4;
obsid=_n_;
run;

goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial' ;  
options nobyline nodate nonumber;
ods escapechar="~";
options nonumber nodate orientation = landscape;
ods graphics / height=3in width=7in noborder;
ods rtf file="S:\Global macros\figures\forest.rtf" nogtitle nogfootnote;
Proc sgplot data=forest nowall noborder nocycleattrs noautolegend;
styleattrs axisextent=data;

highlow y=obsid low=lower high=upper; 
	scatter y=obsid x=orr / markerattrs=(symbol=squarefilled);
	scatter y=obsid x=orr / markerattrs=(size=0) x2axis;

refline 0 / axis=x;
yaxistable subgroup / location=inside position=left labelattrs=(size=8) valuehalign=left indentweight=indentweight;
yaxistable numsubj resp orr lower upper / location=inside position=left labelattrs=(size=8) valueattrs=(size=8) nomissingchar;
yaxis reverse display=none colorbands=odd colorbandsattrs=(transparency=1) offsetmin=0.08;
xaxis display=(nolabel) values=(0 to 100 by 10);
x2axis label='ORR (95% CI)' display=(noline noticks novalues) labelattrs=(size=8) ;
label numsubj = '#Subjects' resp = '#CR/PR' ;


title1 font='Arial' height=0.7 j=left "Hengrui USA"  j=right "Page ~{pageof}";
title2 font='Arial' height=0.7 j=left "Protocol: SHRUS1001" j=right "Program name: forest.sas";
title3 font='Arial' height=0.7 j=left "CSR" ;
title4 font='Arial' height=0.7 j=center "Figure 14.2.2.2.8";
title5 font='Arial' height=0.7 j=center "Forest Plot for ORR, Part 2"; 
title6 font='Arial' height=0.7 j=center "ITT Population";

footnote1 justify=l "~R'\brdrt\brdrs\brdrw5'";



run;
ods rtf close;


