
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
if period in ('Post-First Injection'); 
time=ablrely; 
if ablfl='Y' then chg=0; 
run;


proc sort data=adam.adsl out=temp(keep=usubjid subjid eosdt scrndt tr01sdt tr02sdt); 
by usubjid; 

proc sort data=adlc; by usubjid subjid;
proc sort data=temp; by usubjid subjid;

data adlc;
merge adlc(in=a) temp(in=b);
by usubjid subjid;
if a; 
if scrndt>.z and tr01sdt>.z then time1=(scrndt-tr01sdt)/365.25;
if eosdt>.z and tr01sdt>.z then time2=(eosdt-tr01sdt+1)/365.25; 



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



%mh_mixed_model_3(cond=%str(where grp='grp1' and period='Post-First Injection' and ablfl ne 'Y'), outdata=outdata2,  type=%str(un), solute=solutef1); 

%mh_mixed_model_3(cond=%str(where grp='grp2' and period='Post-First Injection' and ablfl ne 'Y'), outdata=outdata4,  type=%str(un), solute=solutef2); 

data a3; 
set outdata2(in=a) outdata4(in=b);
period='Post-First Injection';
if a then grp='grp1';
else if b then grp='grp2'; 



proc means data=adlc nway noprint;
var base;
class grp period;
where ablfl='Y'; 
output out=base1 mean=meanbase;


proc means data=adlc nway noprint;
var time;
class grp period;
output out=out1 max=max;


proc sort data=out1; by grp period;
proc sort data=base1; by grp period;

data out1;
merge out1 base1;
by grp period; 



data b1(Keep=grp period x meanbase); set out1;
if  period='Post-First Injection'; 
x=max; output;
x=0; output; 



data b3; set b1  ;

proc sort data=a3; by grp period;
proc sort data=b3; by grp period; 

%mh_maxlen(a3, b3, ,,, grp);
%mh_maxlen(a3, b3, ,,, period);


data c3;
merge a3 b3(in=a);
by grp period; 
if a; 
if x>.z and slope>.z and intercep>.z then do;
y=x*slope+intercep+baseline*meanbase; 

end; 


data temp1; set adlc;
if ablfl ne 'Y'; 
keep grp period chg time; 

data final; set c3 temp1;
slopec=strip(put(slope,6.1));
intc=strip(put(intercep, 6.1));
 
if grp='grp1' and period='Post-First Injection' then newgrp='grp2'; 
if grp='grp2' and period='Post-First Injection' then newgrp='grp4'; 
run;

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
grp2="Cohort 1, Post-First Injection, slope = &slope2"
grp4="Cohort 2, Post-First Injection, slope = &slope4"
;
value timef
0='First REACT Injection'
; 


data attrmap; 
length value $100. linecolor fillcolor markercolor $30.;
id='myid'; value="Cohort 1, Post-First Injection, slope = &slope2"; linecolor='blue'; fillcolor='blue'; markercolor='blue'; output;
id='myid'; value="Cohort 2, Post-First Injection, slope = &slope4"; linecolor='red'; fillcolor='red'; markercolor='red'; output;
run;


data final; set final; 
if newgrp in ('grp2','grp4'); 
if time>.z then time=time*12;
if x>.z then x=x*12; 

%maketfl(outname=f_mitt_slop_egfr2, debug=, dotyn=Y);
data _null_; 
fileout=tranwrd("&fileout",'.','_'); 
call symput("fileout", trim(left(fileout)));
run;

options orientation=landscape nodate nonumber; 

data fout.&fileout.; 
set final(keep=y x slope intercep grp period chg time baseline meanbase);
if intercep>.z or chg>.z;
run;


proc sql;
select distinct floor(min(chg)) into : mymin trimmed from final; 
select distinct ceil(max(chg)) into : mymax trimmed from final; 

ods rtf file="%sysfunc(pathname(fout))\&fileout..rtf" style=PKStyle nogtitle nogfootnote;

options orientation=landscape;
	goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial';
	ods graphics /reset=all border=off width=890px height=330px;
	options nobyline nodate nonumber;
	ods escapechar="^";
	

proc sgplot data=final noautolegend dattrmap=attrmap;
where grp='grp1'; 
		yaxis type=linear label="eGFR Change from Baseline (mL/min/1.73 m^{unicode '00b2'x})" values=(-45 to 25 by 5) labelattrs=(size=9);
		xaxis type=linear label="Time (months)" values=(  0 to 36 by 3) labelattrs=(size=9) ;
		
		refline 0 /axis=x lineattrs=(pattern=2);
        scatter y=chg x=time/
		markerattrs=(symbol=circle  size=0.2cm) group=newgrp 
			 legendlabel=' ' attrid=myid  ;

		series x=x y=y/ markers 
            lineattrs=(pattern=solid thickness=0.10cm)
			markerattrs=(symbol=circlefilled  size=0.3cm) group=newgrp groupmc=newgrp
			grouplc=newgrp name='trt01pn' legendlabel=' ' lcattrid=myid mcattrid=myid ;
		keylegend 'trt01pn'/location=outside position=bottom across=2 noborder type=linecolor sortorder=ascending valueattrs=(size=11);
		format newgrp $trtf. time timef.;
title7 "Cohort 1"; 

	run;


proc sgplot data=final noautolegend dattrmap=attrmap;
where grp='grp2'; 
		yaxis type=linear label="eGFR Change from Baseline (mL/min/1.73 m^{unicode '00b2'x})" values=(-45 to 25 by 5) labelattrs=(size=9);
		xaxis type=linear label="Time (months)" values=(  0 to 36 by 3) labelattrs=(size=9) ;
		
		refline 0 /axis=x lineattrs=(pattern=2);
        scatter y=chg x=time/
		markerattrs=(symbol=circle  size=0.2cm) group=newgrp 
			 legendlabel=' ' attrid=myid  ;

		series x=x y=y/ markers 
            lineattrs=(pattern=solid thickness=0.10cm)
			markerattrs=(symbol=circlefilled  size=0.3cm) group=newgrp groupmc=newgrp
			grouplc=newgrp name='trt01pn' legendlabel=' ' lcattrid=myid mcattrid=myid ;
		keylegend 'trt01pn'/location=outside position=bottom across=2 noborder type=linecolor sortorder=ascending valueattrs=(size=11);
		format newgrp $trtf. time timef.;
title7 "Cohort 2"; 

	run;


	ods rtf close; 
