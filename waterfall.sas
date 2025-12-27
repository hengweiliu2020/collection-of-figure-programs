
options sasautos=("S:\Global macros");


libname adam "S:\DEV\CSR\data\adam";
libname sdtm "S:\DEV\CSR\data\sdtm";

%let protocol=SHR001;
%let timepoint=CSR;

data adtr; set adam.adtr; 
where ittfl='Y' and paramcd='TRGTSUM' and tr01pg1='Part 1' and anl01fl='Y';

proc sort data=adtr;
by usubjid descending pchg;
where pchg>.z;

data adtr; set adtr;
by usubjid descending pchg;
if last.usubjid;
run;

** create the waterfall dataset ** ;

proc sort data=adtr out=Waterfall;
by tr01pg1 descending pchg ; 
run;
 
data Waterfall;
set Waterfall;
by tr01pg1 descending pchg;
if first.tr01pg1 then position=0;
Position + 1;   
dose01pc=dose01p||' mg';  
run;

ods rtf file="S:\Global macros\figures\waterfall.rtf" nogtitle nogfootnote;

** create the plot ** ;
options orientation=landscape;
goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial' ;  
ods graphics /reset=all border=off width=850px height=550px;
options nobyline nodate nonumber;
ods escapechar="~";

proc sgplot data=Waterfall noautolegend pad=(bottom=15pct) ;

   refline -0.3 / axis=y lineattrs=(pattern=shortdash);
   vbar Position / response=pchg group=dose01pc groupdisplay=cluster filltype=solid /**datalabel=dose01p datalabelpos=data attrid=myid**/ ;
   xaxis label=" " fitpolicy=thin display=(noticks novalues) values=(1 to 10 by 1);
   yaxis label="Best % Change in Sum of Diameters from Baseline" values=(-100 to 100 by 20 ) ;
   refline -30 20 /axis=y lineattrs=(color=red);

keylegend  /position=topright across=1 location=inside title=' ' noborder;


title1 font='Arial' height=0.7 j=left "Hengrui USA"  j=right "Page ~{pageof}";
title2 font='Arial' height=0.7 j=left "Protocol: XXXXXXXXXX" j=right "Program name: waterfall.sas";
title3 font='Arial' height=0.7 j=left "CSR"   ;
title4 font='Arial' height=0.7 j=center "Figure 14.2.2.2.5.1 Waterfall Plot of Best (Minimum) Percent Change in Sum of Diameters from Baseline in Target Lesions, Part 1";
title5 font='Arial' height=0.7 j=center "ITT Set";

footnote1  "~R/RTF'\brdrt\brdrs '  ";
Footnote2 font='Arial' height=0.7 j=left "Notes: Baseline is defined as the last measurement taken before enrollment.";
footnote3 font='Arial' height=0.7 j=left "For each subject, the best (minimum) percent change from Baseline in the sum of diameters for all target lesions is represented";
footnote4 font='Arial' height=0.7 j=left "by a vertical line.";
footnote5 font='Arial' height=0.7 j=left "Source Data: adtr.adrs";
run;
 
ods rtf close;



