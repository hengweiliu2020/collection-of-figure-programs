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
	obsid=_n_;

	if a or b or c then
		indentweight=1;
	else indentweight=2;



goptions reset=goptions device=sasemf target=sasemf xmax=15in ymax=7.5in ftext='Arial';
options nobyline nodate nonumber;
ods escapechar="~";
options nonumber nodate orientation = landscape;
ods graphics /reset=all border=off width=800px height=405px;

Proc sgplot data=final nowall noborder nocycleattrs noautolegend;
	styleattrs axisextent=data;
	scatter y=obsid x=orr / markerattrs=(symbol=squarefilled) xerrorlower=lower xerrorupper=upper;
	scatter y=obsid x=orr / markerattrs=(size=0) x2axis;
	refline  50 / axis=x;
	yaxistable catlabel / location=inside position=left labelattrs=(size=7) labelhalign=left valuehalign=left indentweight=indentweight;
	yaxistable orr_ci / location=inside position=left labelattrs=(size=7) valueattrs=(size=7) nomissingchar;
	yaxis reverse display=none colorbands=odd colorbandsattrs=(transparency=1) offsetmin=0.08 values=(0 to 10 by 1);
	xaxis display=(nolabel) values=(0 to 100 by 10);
	x2axis label='ORR (95% CI)' display=(noline noticks novalues) labelattrs=(size=7);
	label orr_ci='ORR (95% CI)' catlabel='Subgroup';
run;
