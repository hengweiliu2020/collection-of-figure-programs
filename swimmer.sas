
options sasautos=("S:\Global macros");


libname adam "S:\DEV\CSR\data\adam";
libname sdtm "S:\DEV\CSR\data\sdtm";


filename aa 'S:\Global macros\figures\swimmer.rtf';

%let protocol=SHR;
%let timepoint=CSR;

data adsl; set adam.adsl; where ittfl='Y' and tr01pg1='Part 1';

** get death info ** ;

data b1(keep=usubjid avalc ady ) ; set adsl; where dthfl='Y'; ady=dthdt-trtsdt+1;
avalc='Death';

** get ONGOING status ** ;

data b2(keep=usubjid avalc  ady); set adsl; 
where eotstt> ' ';
ady=trtdurd;
avalc=eotstt;
run;

data a1(keep=usubjid avalc   ady ); set adam.adrs; 
where parcat1='RECIST 1.1' and ittfl='Y' and paramcd='OVRLRESP' and tr01pg1='Part 1'; 

data a2(keep=usubjid cbrsp); set adam.adrs; 
where  ittfl='Y' and paramcd='CBOR' and tr01pg1='Part 1';
cbrsp=avalc;

data final;
set a1 b1 b2;
avisn=round(ady/7,0.1);

proc sort data=final; by usubjid;

data p1(keep=usubjid trtdurw dose01p); set adsl; 
trtdurw=trtdurd/7; 

data final;
merge final(in=a)  a2 p1;
by usubjid;
if a;
idit=strip(scan(usubjid,-1,'-'))||'   '||strip(cbrsp)||'  ';

if avalc='PR' then pr=avisn;
if avalc='SD' then sd=avisn;
if avalc='PD' then pd=avisn;
if avalc='Death' then death=avisn;
if avalc='ONGOING' then ongo=avisn;
if avalc='NE' then ne=avisn;
if avalc='CR' then cr=avisn;
dose01pc=dose01p||' mg'; 

proc sort data=final ;
by  descending trtdurw usubjid;

data final; set final;
by  descending trtdurw usubjid;
if not first.usubjid then trtdurw=.;

options orientation=landscape;
goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial' ;  
options nobyline nodate nonumber;
ods escapechar="~";
ods rtf file=aa nogtitle nogfootnote;

proc sgplot data=final noautolegend ;

hbarparm category=idit response=trtdurw / baselineattrs=(thickness=0)  barwidth=0.3 group=dose01pc legendlabel='Dose' name='Dose';
yaxis type=discrete  label="Patient ID with CBOR"  display=(noticks) labelattrs=(size=7);
xaxis type=linear label=" Treatment Duration (Weeks)" values=(0 to 85 by 5) labelattrs=(size=7);

scatter x=cr y=idit/markerattrs=(symbol=triangle size=7 color=black) legendlabel='CR' name='CR';
scatter x=pr y=idit/markerattrs=(symbol=triangle size=7 color=black) legendlabel='PR' name='PR';
scatter x=pd y=idit/markerattrs=(symbol=trianglefilled size=7 color=black) legendlabel='PD' name='PD';
scatter x=sd y=idit/markerattrs=(symbol=square size=7 color=black) legendlabel='SD' name='SD';
scatter x=death y=idit/markerattrs=(symbol=squarefilled size=7 color=black) legendlabel='Death' name='Death';
scatter x=ongo y=idit/markerattrs=(symbol=arrowright size=7 color=black) legendlabel='Treatment Continues' name='Treatment Continues';
scatter x=ne y=idit/markerattrs=(symbol=circlefilled size=7 color=black) legendlabel='NE' name='NE';
keylegend 'PR' 'SD' 'Treatment Continues' 'PD' 'NE' 'Death' 'Dose'/location=inside position=bottomright across=1 noborder;

title1 font='Arial' height=0.7 j=left "Hengrui USA"  j=right "Page ~{pageof}";
title2 font='Arial' height=0.7 j=left "Protocol: SHRUS1001" j=right "Program name: swimmer.sas";
title3 font='Arial' height=0.7 j=left "CSR" ;
title4 font='Arial' height=0.7 j=center "Figure 14.2.2.2.7.1";
title5 font='Arial' height=0.7 j=center "Swimmer plot of change in Tumor response by Week, Part 1"; 
title6 font='Arial' height=0.7 j=center "ITT Population";

footnote1 justify=l "~R'\brdrt\brdrs\brdrw5'";
Footnote2 font='Arial' height=0.7 j=left "Notes: CR: Complete Response, PR: Partial Response, SD: Stable Disease, ";
footnote3 font='Arial' height=0.7 j=left "PD: Progressive, NE: Non-evaluable. Best overall response was assessed using RECIST criteria, Version 1.1.";
footnote4 font='Arial' height=0.7 j=left "Source Data: adam.adrs";

run;

ods rtf close;
run;


