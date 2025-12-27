options sasautos=("S:\Global macros");


libname adam "S:\DEV\CSR\data\adam";
libname sdtm "S:\DEV\CSR\data\sdtm";


filename aa 'S:\Global macros\figures\spider.rtf';

%let protocol=SHR1;
%let timepoint=CSR;

data aa(keep=usubjid pchg adt tr01pg1 avisitn week dose01pc); 
set adam.adtr;
where paramcd='TRGTSUM' and anl01fl='Y' and ittfl='Y' and tr01pg1='Part 1';

if ablfl='Y' then do; pchg=0; week=0; end;
else do; week=ady/7; end;
dose01pc=dose01p||' mg'; 
run;



%macro plotit; 

options orientation=landscape;

goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial' ;  
ods graphics /reset=all border=off width=850px height=550px;
options nobyline nodate nonumber;
ods escapechar="~";
ods rtf file=aa nogtitle nogfootnote;

proc sgplot data=aa noautolegend;

yaxis type=linear label="% Change in Sum of Diameters from Baseline" values=(-100 to 100 by 20) labelattrs=(size=7);
xaxis type=linear label="Time (Weeks) from Enrollment" values=(0 to 85) /**valuesdisplay=('Baseline' %do k=2 %to 85 %by 5; "&k" %end;)**/;
refline -0.3 / axis=y lineattrs=(pattern=shortdash);
refline 0 /axis=y lineattrs=(color=red);

series x=week y=pchg/markers 
                
                 lineattrs=(color=blue pattern=solid)
                 markerattrs=(symbol=circlefilled color=blue) group=usubjid grouplc=dose01pc name='Dose'
                 ;

keylegend 'Dose'/location=inside position=bottomright across=1 noborder type=linecolor;

title1 font='Arial' height=0.7 j=left "Hengrui USA"  j=right "Page ~{pageof}";
title2 font='Arial' height=0.7 j=left "Protocol: XXXXXXXXXX" j=right "Program name: spider.sas";
title3 font='Arial' height=0.7 j=left "CSR"  ;
title4 font='Arial' height=0.7 j=center "Figure 14.2.2.2.4.1 A spider Plot of the Percent Change in the Sum of the Diameters by Subject, Part 1";
title5 font='Arial' height=0.7 j=center "ITT population";

footnote1  "~R/RTF'\brdrt\brdrs '  ";
footnote2 font='Arial' height=0.7 j=left "Source Data: adtr.adrs";
run;
 
				 
ods rtf close;

%mend;
%plotit;
