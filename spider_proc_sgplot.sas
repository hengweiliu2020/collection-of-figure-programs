

libname adam "C:\paper";

data attrmap; 
length value $30. linecolor fillcolor markercolor $30.;
id='myid'; value='trt1'; linecolor='red'; fillcolor='red'; markercolor='red'; output;
id='myid'; value='trt2'; linecolor='green'; fillcolor='green'; markercolor='green'; output;
id='myid'; value='trt3'; linecolor='blue'; fillcolor='blue'; markercolor='blue'; output;
run;

data adtr;
	set adam.adtr;
	where paramcd='SUMDIAM' ;
	week=ady/7; 

proc sql;
select ceil(max(week)+2) into :xmax from adtr; 

proc sort data=adtr; by trt01p subjid week; 

	options orientation=landscape;
	goptions reset=goptions device=sasemf target=sasemf xmax=10in ymax=7.5in ftext='Arial';
	ods graphics /reset=all border=off width=850px height=550px;
	options nobyline nodate nonumber;
	ods escapechar="~";
	
filename aa 'C:\paper\spider_sumdiam.rtf';
ods rtf file=aa nogtitle nogfootnote;

proc sgplot data=adtr noautolegend dattrmap=attrmap;

		yaxis type=linear label="% Change in Sum of Diameters from Baseline" values=(-100 to 100 by 20) labelattrs=(size=9);
		xaxis type=linear label="Time (weekss) from Treatment Start" values=(0 to &xmax by 1) labelattrs=(size=9);
		refline -30 / axis=y lineattrs=(pattern=2);
		refline 20 / axis=y lineattrs=(pattern=2);
		refline 0 /axis=y lineattrs=(pattern=2);

		series x=week y=pchg/ markers 
            lineattrs=(pattern=solid thickness=0.12cm)
			markerattrs=(symbol=circlefilled color=black size=0.3cm) group=subjid groupmc=trt01p
			grouplc=trt01p name='trt01pn' legendlabel=' ' lcattrid=myid mcattrid=myid ;
		keylegend 'trt01pn'/location=inside position=topright across=1 noborder type=linecolor sortorder=ascending;
	run;

	ods rtf close;
	
