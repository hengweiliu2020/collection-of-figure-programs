
options sasautos=("S:\Global macros");


libname adam "S:\DEV\Pyrotinib\SHRUS1001\CSR\data\adam";
libname sdtm "S:\DEV\Pyrotinib\SHRUS1001\CSR\data\sdtm";


data adpc; set adam.adpc; 
where pkfl='Y' and dose01p>.z; 


filename aa "S:\Global macros\figures\concentration_by_subject.rtf"; 
ods rtf file=aa nogtitle nogfootnote;

ods graphics on / height=6in width=10in;
options orientation=landscape ;
goptions reset=goptions device=sasemf target=sasemf  ftext='Arial' ;  
options nobyline nodate nonumber;
ods escapechar="~";


proc sgpanel data=adpc;
panelby usubjid /columns=2 rows=3 novarname nowall ; 
where avisitn=10101;


series x=atptn y=aval/markers 
     markerattrs=(symbol=square size=5pt color=blue)
     ; 

title1 font='Arial' height=0.7 j=left "Hengrui USA"  j=right "Page ~{pageof}";
title2 font='Arial' height=0.7 j=left "Protocol: SHRUS1001" j=right "Program name: concentration_by_subject.sas";
title3 font='Arial' height=0.7 j=left "CSR" ;
title4 font='Arial' height=0.7 j=center "Figure 14.2.1.3";
title5 font='Arial' height=0.7 j=center "Individual Plasma Concentration VS time"; 
title6 font='Arial' height=0.7 j=center "PK Population";
run;

ods rtf close;
