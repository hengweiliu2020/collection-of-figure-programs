
options sasautos=("S:\Global macros");


libname adam "S:\DEV\CSR\data\adam";
libname sdtm "S:\DEV\CSR\data\sdtm";


proc sql;
select distinct avisitn, avisit, atptn, atpt from adam.adpc; 


proc means data=adam.adpc nway noprint; 
where pkfl='Y' and 1<=atptn<=24 and dose01p>.z; 
var aval;
class dose01p avisitn atptn;
output out=out1(drop=_type_ _freq_) mean=mean std=std stderr=stderr;

proc sort data=out1;by avisitn;
run;

data out1; set out1; 
lower=mean - std;                                                                                                                 
upper=mean + std;        
dose01pc=compbl(dose01p||' mg'); 
if dose01p=400 then atptn=atptn+0.2;
run;                    


filename aa "S:\Global macros\figures\concentration.rtf"; 
ods rtf file=aa nogtitle nogfootnote;


%macro doit(k=, avisitn=, avisit=); 

filename a&k "S:\Global macros\figures\concentration&k.rtf"; 

options orientation=landscape;
goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial' ;  
options nobyline nodate nonumber;
ods escapechar="~";
ods rtf(&k) file=a&k nogtitle nogfootnote;

proc sgplot data=out1;
where avisitn=&avisitn; 

scatter x=atptn y=mean /                                                                                           
                           yerrorupper=upper                                                                                            
                           markerattrs=(color=blue symbol=CircleFilled);
series x=atptn y=mean/markers 
     markerattrs=(symbol=square size=5pt color=blue)
     name="a" group=dose01pc; 

keylegend "a" / location=outside position=bottomright across=1 noborder;

title1 font='Arial' height=0.7 j=left "Hengrui USA"  j=right "Page ~{pageof}";
title2 font='Arial' height=0.7 j=left "Protocol: SHRUS1001" j=right "Program name: concentration.sas";
title3 font='Arial' height=0.7 j=left "CSR" ;
title4 font='Arial' height=0.7 j=center "Figure 14.2.1.1";
title5 font='Arial' height=0.7 j=center "Mean (SD) Plasma Concentration VS time"; 
title6 font='Arial' height=0.7 j=center "PK Population";
title7 font='Arial' height=0.7 j=center "&avisit"; 

footnote1 justify=l "~R'\brdrt\brdrs\brdrw5'";
run;


run;

ods rtf(&k) close; 

%mend;

%doit(k=1, avisitn=10101, avisit=Cycle 1 day 1);
%doit(k=2, avisitn=10128, avisit=Cycle 1 day 28);

ods rtf close;  
