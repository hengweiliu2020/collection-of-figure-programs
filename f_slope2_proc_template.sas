

%include "minit.sas";

data adsl; set adam.adsl; 
if mittfl='Y'; 

data adsl1; set adsl; if trt01pn=1; grp='grp1'; 
data adsl2; set adsl; if trt01pn=2; grp='grp2'; 

data adsl; set adsl1 adsl2;
%mh_bign(classvar=grp);


data adlc; set adam.adeff;
if paramcd='EGFR2009' and anl01fl='Y';
period=s01perd;
if ( period in ('Pre-Injection') and basetype = 'Last Result Including MHCKD') or  (period='Post-Last Injection' and basetype='Reference to Last Injection'); 
time=ABLRELY; 


proc sort data=adam.adsl out=temp(keep=usubjid subjid eosdt scrndt tr01sdt tr02sdt); 
by usubjid; 

proc sort data=adlc; by usubjid subjid;
proc sort data=temp; by usubjid subjid;

data adlc;
merge adlc(in=a) temp(in=b);
by usubjid subjid;
if a; 
if scrndt>.z and tr01sdt>.z then time1=(scrndt-tr01sdt)/365.25;
if eosdt>.z and tr01sdt>.z then time2=(eosdt-max(tr01sdt, tr02sdt)+1)/365.25; 

data adlc1; set adlc; if trt01pn=1; grp='grp1'; 
data adlc2; set adlc; if trt01pn=2; grp='grp2'; 

data adlc; set adlc1 adlc2; 

proc sort data=adlc; by grp usubjid;
proc sort data=adsl; by grp usubjid;

data adlc;
merge adlc(in=a) adsl(in=b);
by grp usubjid;
if a and b; 

proc sort data=adlc; by grp period; 
run;

%mh_mixed_model_4(cond=%str(where grp='grp1' ), outdata1=zout1, outdata2=zout2, outvar1=col1, outvar2=col2, type=%str(UN)); 

data z1(keep=intercep); set solution; if effect='Intercept'; intercep=estimate; 
data z2(Keep=slope); set solution; if effect='TIME'; slope =estimate; 
data z3(Keep=baseline); set solution; if effect='BASE'; baseline=estimate; 
data z4(Keep=prd period); set solution; if effect='PERIOD'; prd=estimate; 
data z5(Keep=interact period); set solution; if effect='TIME*PERIOD'; interact=estimate; 

data z2a(keep=slope); set estimates; if label='Slope of Post-last injection period'; slope =estimate; 

data myout1; 
length period $200; 
merge z1 z2 z3; 
grp='grp1';
period='Pre-Injection'; 
run;

data myout2; 
length period $200; 
merge z1 z2a z3; 
grp='grp1';
period='Post-Last Injection'; 
run;

proc sort data=z4; by period;
proc sort data=z5; by period; 


data myout1; set myout1 myout2;
data z4; merge z4 z5;  by period ; 

proc sort data=myout1; by period;
proc sort data=z4; by period;


data myout1;
merge myout1 z4;
by period; 


%mh_mixed_model_4(cond=%str(where grp='grp2' ), outdata1=zout3, outdata2=zout4, outvar1=col3, outvar2=col4, type=%str(UN)); 



data z1(keep=intercep); set solution; if effect='Intercept'; intercep=estimate; 
data z2(Keep=slope); set solution; if effect='TIME'; slope =estimate; 
data z3(Keep=baseline); set solution; if effect='BASE'; baseline=estimate; 
data z4(Keep=prd period); set solution; if effect='PERIOD'; prd=estimate; 
data z5(Keep=interact period); set solution; if effect='TIME*PERIOD'; interact=estimate; 

data z2a(keep=slope); set estimates; if label='Slope of Post-last injection period'; slope =estimate; 

data myout3; 
length period $200; 
merge z1 z2 z3; 
grp='grp2';
period='Pre-Injection'; 
run;

data myout4; 
length period $200; 
merge z1 z2a z3; 
grp='grp2';
period='Post-Last Injection'; 
run;

proc sort data=z4; by period;
proc sort data=z5; by period; 


data myout3; set myout3 myout4;
data z4; merge z4 z5; by period;  

proc sort data=myout3; by period;
proc sort data=z4; by period;

data myout3;
merge myout3 z4;
by period; 


data a3; set myout1  myout3;

proc means data=adlc nway noprint;
var base;
where ablfl='Y';
class grp period;
output out=base1 mean=meanbase;

proc means data=adlc nway noprint;
var time;
class grp period;
output out=out1 max=max;

proc means data=adlc nway noprint;
var time;
class grp period;
output out=out2 min=min;

proc means data=adlc nway noprint;
var time;
class grp period;
output out=out3 mean=meantime;

proc sort data=out1; by grp period;
proc sort data=base1; by grp period;
proc sort data=out2; by grp period; 
proc sort data=out3; by grp period; 

data out1;
merge out1 base1 out2 out3;
by grp period; 

data b1(Keep=grp period x meanbase meantime); set out1;
if  period='Post-Last Injection'; 
x=max; output;
x=0; output; 

data b2(keep=grp period x meanbase meantime); set out1;
if  period='Pre-Injection'; 
x=min; output;
x=0; output; 

data b3; set b1 b2;

proc sort data=a3; by grp period;
proc sort data=b3; by grp period; 

%mh_maxlen(a3, b3, ,,, grp);
%mh_maxlen(a3, b3, ,,, period);


data c3;
merge a3 b3;
by grp period; 

if x>.z and slope>.z and intercep>.z then do; 
y=x*slope+intercep+baseline*meanbase + prd*1; 
end; 

proc print data=c3(keep=grp period x y slope intercep baseline meanbase prd interact );
run;



data temp1; set adlc;
keep grp period chg time ablfl; 
run;

****************************;
** put everything together;
***************************;

data final; set c3 temp1;
slopec=strip(put(slope,6.1)); 
intc=strip(put(intercep, 6.1)); 

if grp='grp1' and period='Pre-Injection' then newgrp='grp1'; 
if grp='grp1' and period='Post-Last Injection' then newgrp='grp2'; 
if grp='grp2' and period='Pre-Injection' then newgrp='grp3'; 
if grp='grp2' and period='Post-Last Injection' then newgrp='grp4'; 



proc sort data=final; by newgrp x; 


proc sql noprint;
select distinct slopec into :slope1 trimmed from final where newgrp='grp1' and slopec>''; 
select distinct slopec into :slope2 trimmed from final where newgrp='grp2' and slopec>''; 
select distinct slopec into :slope3 trimmed from final where newgrp='grp3' and slopec>''; 
select distinct slopec into :slope4 trimmed from final where newgrp='grp4' and slopec>''; 

select distinct intc into :int1 trimmed from final where newgrp='grp1' and intc>''; 
select distinct intc into :int2 trimmed from final where newgrp='grp2' and intc>''; 
select distinct intc into :int3 trimmed from final where newgrp='grp3' and intc>''; 
select distinct intc into :int4 trimmed from final where newgrp='grp4' and intc>''; 
quit;

proc format;
value $trtf
grp1="Cohort 1, Pre-Injection, slope = &slope1"
grp2="Cohort 1, Post-Last Injection, slope = &slope2"
grp3="Cohort 2, Pre-Injection, slope = &slope3"
grp4="Cohort 2, Post-Last Injection, slope = &slope4"
;

run;


data attrmap; 
length value $100 linecolor fillcolor markercolor  $30;
id='myid'; value="Cohort 1, Pre-Injection, slope = &slope1"; linecolor='blue'; fillcolor='blue'; markercolor='blue'; linepattern=20; linethickness=0.1; output;
id='myid'; value="Cohort 1, Post-Last Injection, slope = &slope2"; linecolor='blue'; fillcolor='blue'; markercolor='blue'; linepattern=1; linethickness=0.1; output;
id='myid'; value="Cohort 2, Pre-Injection, slope = &slope3"; linecolor='red'; fillcolor='red'; markercolor='red'; linepattern=20; linethickness=0.1; output;
id='myid'; value="Cohort 2, Post-Last Injection, slope = &slope4"; linecolor='red'; fillcolor='red'; markercolor='red'; linepattern=1; linethickness=0.1; output;
run;



%maketfl(outname=f_mitt_slop_egfr1, debug=, dotyn=Y);
data _null_; 
fileout=tranwrd("&fileout",'.','_'); 
call symput("fileout", trim(left(fileout)));
run;

options orientation=landscape nodate nonumber; 



proc sql;
select distinct floor(min(chg)-2) into : mymin trimmed from final; 
select distinct floor(max(chg)) into : mymax trimmed from final; 
select distinct min(x) into : myminx1 trimmed from final where grp='grp1'; 
select distinct min(x) into : myminx2 trimmed from final where grp='grp2'; 

data anno1; length label function x1space y1space $30.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='graphpercent'; y1space='graphpercent'; textsize=9; textweight='normal'; width=20; 
label='Screening'; style = "Courier new"; 
y1=28; x1=10; rotate=30; 

run;

data anno2; length label function x1space y1space $30.; 
retain function x1space y1space textsize textweight width y1 ;
function='text'; x1space='graphpercent'; y1space='graphpercent'; textsize=9; textweight='normal'; width=20; 
label='Last REACT Injection'; style = "Courier new"; 
y1=31; x1=59;  rotate=30; 

run;

data anno; set anno1 anno2; 




data final; set final; 
if time>.z then time=time*12;
if x>.z then x=x*12; 

data fout.&fileout.; 
set final(keep=y x slope intercep baseline grp period chg time meanbase);
if intercep>.z or chg>.z;
run;



data a1(keep=x y chg time newgrp); set final; 
where grp='grp1' and period='Pre-Injection'; 

data a2(keep=x2 y2 chg2 time2 newgrp2); set final; 
where grp='grp1' and period='Post-Last Injection'; 
x2=x;
y2=y;
chg2=chg;
time2=time;
newgrp2=newgrp; 

data a1; set a1; ord=_n_;
data a2; set a2; ord=_n_;
data a3;
merge a1 a2;
by ord; 



data b1(keep=x y chg time newgrp); set final; 
where grp='grp2' and period='Pre-Injection'; 

data b2(keep=x2 y2 chg2 time2 newgrp2); set final; 
where grp='grp2' and period='Post-Last Injection'; 
x2=x;
y2=y;
chg2=chg;
time2=time;
newgrp2=newgrp; 

data b1; set b1; ord=_n_;
data b2; set b2; ord=_n_;
data b3;
merge b1 b2;
by ord; 


 proc template;
 define statgraph side_by_side;
 begingraph ;

discreteattrmap name = "myid";
 value "Cohort 1, Pre-Injection, slope = &slope1" / fillattrs = (color = blue ) lineattrs = (pattern=dash color = blue) MARKERATTRS=(color = blue) ;
 value "Cohort 1, Post-Last Injection, slope = &slope2" / fillattrs = (color = blue ) lineattrs = (pattern=solid color = blue) MARKERATTRS=(color = blue) ;
 value "Cohort 2, Pre-Injection, slope = &slope3" / fillattrs = (color = red ) lineattrs = (pattern=dash color = red) MARKERATTRS=(color = red) ;
 value "Cohort 2, Post-Last Injection, slope = &slope4" / fillattrs = (color = red ) lineattrs = (pattern=solid color = red) MARKERATTRS=(color = red) ;
  value " " / fillattrs = (color = white ) lineattrs = (pattern=solid color = white) MARKERATTRS=(color = white) ;

enddiscreteattrmap;

discreteattrvar attrvar = newgrp var = newgrp attrmap = "myid";
discreteattrvar attrvar = newgrp2 var = newgrp2 attrmap = "myid";

 layout lattice / columns = 2  rowgutter=1 columngutter=1;
layout overlay / xaxisopts=(offsetmin=0.05 offsetmax=0.05
linearopts=(tickvaluepriority=true TICKVALUESEQUENCE=(START=-30 END=0
INCREMENT=3)) offsetmin=0.01 offsetmax=0.01 label="Time (months)" type=linear  )

yaxisopts=(griddisplay=on gridattrs=(thickness= 0.05 color=lightgrey)
linearopts=(tickvaluepriority=true TICKVALUESEQUENCE=(START=-30 END=70
INCREMENT=10)) offsetmin=0.01 offsetmax=0.01 label="eGFR Change from Baseline ^{Unicode '000A'x}(mL/min/1.73 m^{unicode '00b2'x})" type=linear  );
 
    scatterplot y=chg x=time/
		markerattrs=(symbol=circle  size=0.2cm) group=newgrp 
			 legendlabel=' '   ;

		seriesplot x=x y=y/ 
            lineattrs=(pattern=dash thickness=0.10cm)
			markerattrs=(symbol=circlefilled  size=0.2cm)  group=newgrp name='trt';
		
       discretelegend 'trt' / title= " " titleattrs= (size=9pt
weight=normal ) location= outside halign=left valign=bottom
valueattrs= (size=11pt) border=false across=1 sortorder=ascendingformatted;
 endlayout;

layout overlay/ xaxisopts=(offsetmin=0.05 offsetmax=0.05
linearopts=(tickvaluepriority=true TICKVALUESEQUENCE=(START=0 END=30
INCREMENT=3)) offsetmin=0.03 offsetmax=0.03 label="Time (months)" type=linear  )

yaxisopts=( griddisplay=on gridattrs=(thickness= 0.05 color=lightgrey)
linearopts=(tickvaluepriority=true TICKVALUESEQUENCE=(START=-30 END=70
INCREMENT=10)) offsetmin=0.01 offsetmax=0.01 label="eGFR Change from Baseline ^{Unicode '000A'x}(mL/min/1.73 m^{unicode '00b2'x})"  type=linear display=(ticks ));
 
    scatterplot y=chg2 x=time2/
		markerattrs=(symbol=circle  size=0.2cm) group=newgrp2 
			 legendlabel=' '   ;

		seriesplot x=x2 y=y2/ 
            lineattrs=( pattern=solid thickness=0.10cm)
			markerattrs=(symbol=circlefilled  size=0.2cm) group=newgrp2  name='trt2';
	
discretelegend 'trt2' / title= " " titleattrs= (size=9pt
weight=normal ) location= outside halign=left valign=bottom
valueattrs= (size=11pt) border=false across=1 sortorder=ascendingformatted;

 endlayout;
endlayout;
 endgraph;
 end;
 run;



proc means data=final nway;
var chg ;
class period;
run;


proc means data=final nway;
var time ;
class period;
run;




ods listing close; 
ods rtf file="%sysfunc(pathname(fout))\&fileout..rtf" style=PKStyle nogtitle nogfootnote;

options orientation=landscape;
	goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial';
	ods graphics /reset=all border=off width=890px height=330px;
	options nobyline nodate nonumber;
	ods escapechar="^";
	
proc sgrender data=a3 template=side_by_side;
format newgrp newgrp2 $trtf.; 
title7 "Cohort 1"; 
run;

proc sgrender data=b3 template=side_by_side;
format newgrp newgrp2 $trtf.; 
title7 "Cohort 2"; 

run;

	ods rtf close; 
