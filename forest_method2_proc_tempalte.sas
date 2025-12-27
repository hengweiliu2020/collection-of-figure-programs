options sasautos=("/home/heliu/forest");

data bor;
	length race sex region $10;
	usubjid='0001';
	avalc='PR';
	race='White';
	sex='Male';
	region='Japan';
	paramcd='BOR';
	output;
	usubjid='0002';
	avalc='PD';
	race='White';
	sex='Female';
	region='Japan';
	paramcd='BOR';
	output;
	usubjid='0003';
	avalc='SD';
	race='White';
	sex='Male';
	region='USA';
	paramcd='BOR';
	output;
	usubjid='0004';
	avalc='SD';
	race='White';
	sex='Female';
	region='Japan';
	paramcd='BOR';
	output;
	usubjid='0005';
	avalc='SD';
	race='White';
	sex='Male';
	region='Japan';
	paramcd='BOR';
	output;
	usubjid='0006';
	avalc='PR';
	race='Asian';
	sex='Female';
	region='USA';
	paramcd='BOR';
	output;
	usubjid='0007';
	avalc='CR';
	race='Asian';
	sex='Male';
	region='Japan';
	paramcd='BOR';
	output;
	usubjid='0008';
	avalc='SD';
	race='Asian';
	sex='Female';
	region='Japan';
	paramcd='BOR';
	output;
	usubjid='0009';
	avalc='PD';
	race='Asian';
	sex='Male';
	region='USA';
	paramcd='BOR';
	output;
	usubjid='0010';
	avalc='NE';
	race='White';
	sex='Female';
	region='USA';
	paramcd='BOR';
	output;
run;



	%m_bign(inadsl=bor, classvar=race);
	%m_orr(tagn=1, tag=Race, indata=bor, classvar=race, outdata=p1, where=, catlabel=orr#CI, cond=%str(avalc in ('CR','PR')));
	%m_bign(inadsl=bor, classvar=sex);
	%m_orr(tagn=1, tag=Sex, indata=bor, classvar=sex, outdata=p2, where=, catlabel=orr#CI, cond=%str(avalc in ('CR','PR')));
	%m_bign(inadsl=bor, classvar=region);
	%m_orr(tagn=1, tag=Region, indata=bor, classvar=region, outdata=p3, where=, catlabel=orr#CI, cond=%str(avalc in ('CR','PR')));

%macro getcat(indata=, outdata=, var=);

	data &outdata(Keep=catlabel orr_ci orr lower upper);
		length catlabel $100;
		set &indata;
		catlabel="&var";
		orr= input(scan(&var,1,' '), best.);
		lower= input(scan(compress(scan(&var,2,'('),')'),1,','), best.);
		upper= input(scan(compress(scan(&var,2,'('),')'),2,','), best.);
		orr_ci=&var;
%mend;

data a1;
	length catlabel $100;
	catlabel='Race';

	%getcat(indata=p1, outdata=a2, var=Asian);
	%getcat(indata=p1, outdata=a3, var=White);

data a4;
	length catlabel $100;
	catlabel='Sex';

	%getcat(indata=p2, outdata=a5, var=Male);
	%getcat(indata=p2, outdata=a6, var=Female);

data a7;
	length catlabel $100;
	catlabel='Region';

	%getcat(indata=p3, outdata=a8, var=Japan);
	%getcat(indata=p3, outdata=a9, var=USA);

data final;
	set a1(in=a) a2 a3 a4(in=b) a5 a6 a7(in=c) a8 a9;
	start=10-_n_;

	if a or b or c then
		indentweight=1;
	else indentweight=2;

proc format;
	value catf
		1='USA'
		2='Japan'
		3='Region'
		4='Female'
		5='Male'
		6='Sex'
		7='White'
		8='Asian'
		9='Race'
	;



goptions reset=goptions device=sasemf target=sasemf xmax=15in ymax=7.5in ftext='Arial';
options nobyline nodate nonumber;
ods escapechar="~";
options nonumber nodate orientation = landscape;
ods graphics /reset=all border=off width=800px height=405px;

proc template;
	define statgraph forest;
		begingraph;
			entrytitle textattrs=(size=10.9pt weight=bold) halign = center "Forest plot of ORR with 95% CI";
			entrytitle " ";
			layout overlay/yaxisopts=(linearopts=(tickvaluelist=(1 2 3 4 5 6 7 8 9)) label=' ' tickvaluehalign=left)
				xaxisopts=(linearopts=(tickvaluepriority=true tickvaluesequence=(start=0 end=100 increment=10)) offsetmin= 0.2 offsetmax=0.1 label=' ');
				axistable y=start value=orr_ci / valueattrs=(size=10 ) display=(values);
				scatterplot x=orr y=start /  
					ERRORBARCAPSHAPE= serif 
					xerrorlower=lower xerrorupper=upper errorbarattrs=(color=blue)
					markerattrs=(symbol=circlefilled size=8 color=blue );
				referenceline x=50 / lineattrs= ( pattern=2);
				drawtext textattrs=( size=9pt) "Subgroup" /anchor=bottomleft width=18
					widthunit=percent 
					xspace=wallpercent yspace=wallpercent x=-7 y=99 justify=center;
				drawtext textattrs=( size=9pt) "ORR (95% CI)" /anchor=bottomleft width=18
					widthunit=percent 
					xspace=wallpercent yspace=wallpercent x=4 y=99 justify=center;
			endlayout;
		endgraph;
	end;
run;

proc sgrender data=final template=forest;
	format start catf.;
run;
