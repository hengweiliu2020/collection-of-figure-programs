
data adtte; 
subjid='0001'; grp='grp1'; cnsr=0; aval=5; output; 
subjid='0002'; grp='grp1'; cnsr=1; aval=10; output; 
subjid='0003'; grp='grp1'; cnsr=0; aval=21; output; 
subjid='0004'; grp='grp1'; cnsr=1; aval=7; output; 
subjid='0005'; grp='grp1'; cnsr=1; aval=19; output; 
subjid='0006'; grp='grp2'; cnsr=0; aval=13; output; 
subjid='0007'; grp='grp2'; cnsr=0; aval=6; output; 
subjid='0008'; grp='grp2'; cnsr=1; aval=12; output; 
subjid='0009'; grp='grp2'; cnsr=1; aval=17; output; 
subjid='0010'; grp='grp2'; cnsr=0; aval=8; output; 

ods graphics on ;
ods output Survivalplot=SurvivalPlot quartiles=quart;

proc lifetest data=adtte plots=survival(cl test atrisk(outside(0.15))=0 to 24 by 2) ;
time aval*cnsr(1); * 1 is for censored patients;
strata grp;
run;


data a0(keep=grp0 tatrisk stratum); set survivalplot;
if stratum='grp1' and tatrisk>.z ;
grp0=''; 
label grp0='Subjects still at risk';

data a1(keep=grp1 tatrisk stratum); set survivalplot;
if stratum='grp1' and tatrisk>.z ;
grp1=strip(put(atrisk, best.));

data a2(keep=grp2 tatrisk stratum);  set survivalplot;
if stratum='grp2' and tatrisk>.z ;
grp2=strip(put(atrisk, best.));
stratum='grp1'; 

proc sort data=survivalplot; by stratum tatrisk;
proc sort data=a0; by stratum tatrisk;
proc sort data=a1; by stratum tatrisk;
proc sort data=a2; by stratum tatrisk;


data survivalplot;
merge survivalplot a0 a1 a2;
by stratum tatrisk; 

data _null_;
set quart;
where stratum=1 and percent=50;
if estimate>.z then estc=put(estimate,5.1); 
else estc='NE'; 

if lowerlimit>.z then lowerc=put(lowerlimit,5.1);
else lowerc='NE';
if upperlimit>.z then upperc=put(upperlimit,5.1);
else upperc='NE';
mci=compbl(estc||'('||lowerc||','||upperc||')');
call symput('grp1', mci); 
run;

data _null_;
set quart;
where stratum=2 and percent=50;
if estimate>.z then estc=put(estimate,5.1); 
else estc='NE'; 

if lowerlimit>.z then lowerc=put(lowerlimit,5.1);
else lowerc='NE';
if upperlimit>.z then upperc=put(upperlimit,5.1);
else upperc='NE';
mci=compbl(estc||'('||lowerc||','||upperc||')');
call symput('grp2', mci); 
run;


data attrmap; 
length value $30. linecolor fillcolor markercolor $30.;
id='myid'; value='grp1'; linecolor='red'; fillcolor='red'; 
markercolor='red'; output;
id='myid'; value='grp2'; linecolor='blue'; fillcolor='blue'; 
markercolor='blue'; output;

run;

options orientation=landscape mprint mlogic symbolgen;
goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial' ;  
ods graphics /reset=all border=off width=850px height=400px;
options nobyline nodate nonumber;
ods escapechar="~";

proc sgplot data=survivalplot  dattrmap=attrmap;
   step x=time y=survival/group=stratum legendlabel='Trt' name='Trt' attrid=myid;
   xaxis label='Time (Months)' values=(0 to 24 by 2);
   yaxis label='Progression-Free Survival Probability ';

   scatter x=time y=censored/markerattrs=(symbol=plus size=7 color=black) legendlabel='Censor' name='Censor';
   keylegend 'Censor' "Trt" /location=inside position=bottomleft across=1 noborder;
   xaxistable  grp0 grp1 grp2/location=outside label x=tatrisk;
   inset   ("grp1"="&grp1"
            "grp2"="&grp2")/title="Median (CI)" position=topright opaque border;
    
run;

