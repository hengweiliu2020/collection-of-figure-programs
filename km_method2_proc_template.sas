data adtte; 
subjid='0001'; grp='grp1'; cnsr=0; aval=5; output; 
subjid='0002'; grp='grp1'; cnsr=1; aval=10; output; 
subjid='0003'; grp='grp1'; cnsr=0; aval=21; output; 
subjid='0004'; grp='grp1'; cnsr=1; aval=7; output; 
subjid='0005'; grp='grp1'; cnsr=1; aval=19; output; 
subjid='0006'; grp='grp2'; cnsr=0; aval=13; output; 
subjid='0007'; grp='grp2'; cnsr=0; aval=6; output; 
subjid='0008'; grp='grp2'; cnsr=1; aval=12; output; 
subjid='0009'; grp='grp2'; cnsr=1; aval=17; output; 
subjid='0010'; grp='grp2'; cnsr=0; aval=8; output; 
	



	ods graphics on;
	ods output Survivalplot=SurvivalPlot quartiles=quart;

proc lifetest data=adtte plots=survival(cl test atrisk(outside(0.15))=0 to 24 by 2);
	time aval*cnsr(1);

	* 1 is for censored patients;
	strata grp;
run;

data _null_;
	set quart;
	where stratum=1 and percent=50;
if estimate>.z then estc=put(estimate,5.1); 
else estc='NE'; 

	if lowerlimit>.z then
		lowerc=put(lowerlimit,5.1);
	else lowerc='NE';

	if upperlimit>.z then
		upperc=put(upperlimit,5.1);
	else upperc='NE';
	mci=compbl('grp1: '||estc||'('||lowerc||','||upperc||')');
	call symput('grp1', mci);
run;

data _null_;
	set quart;
	where stratum=2 and percent=50;
if estimate>.z then estc=put(estimate,5.1); 
else estc='NE'; 

	if lowerlimit>.z then
		lowerc=put(lowerlimit,5.1);
	else lowerc='NE';

	if upperlimit>.z then
		upperc=put(upperlimit,5.1);
	else upperc='NE';
	mci=compbl('grp2: '||estc||'('||lowerc||','||upperc||')');
	call symput('grp2', mci);
run;


proc template;
	define statgraph km2;
		begingraph;
			discreteattrmap name='Attr_trt';
			value 'grp1' / lineattrs=(color=red pattern=solid);
			value 'grp2' / lineattrs=(color=blue pattern=solid);
			enddiscreteattrmap;
			discreteattrvar attrvar=Attr_trtname var=stratum 
				attrmap='Attr_trt';
			entrytitle textattrs=(size=11pt weight=bold) halign = center 'KaplanMeier plot';
			entrytitle " ";
			layout lattice / columns=1 rows=2 rowweights= (0.85 0.15) 
				columndatarange=union;

				/*step plot*/
				layout overlay/xaxisopts=(offsetmin=0.15 offsetmax=0.1
					label = "Months"
					linearopts=(tickvaluelist= (0 2 4 6 8 10 12 14 16 18 20 22 24)))
					yaxisopts=(offsetmin=0.1 offsetmax=0.28 label = 'Probability of 
					progression'
					linearopts=(TICKVALUEPRIORITY = true tickvaluesequence=(start=0
					end=1 increment=0.1)));
					stepplot x= time y= survival /group=Attr_trtname name='step';
					scatterplot x= time y= censored /group=Attr_trtname 
						name='scatter' markerattrs=(symbol=plus color=black);
					discretelegend 'step' /location= inside halign=left 
						valign=bottom valueattrs=(size=8) border= yes across=1;
					layout gridded/rows=3 columns=1 
						autoalign=( topright) border=true 
						opaque=true 
						backgroundcolor=GraphWalls:color;
						entry halign=left "Median (CI)";
						entry halign=left "&grp1";
						entry halign=left "&grp2";
					endlayout;
				endlayout;

				/*no.of subjects at bottom presented as plot*/
				Layout Overlay / walldisplay=none xaxisopts=(display=none 
					griddisplay=off displaySecondary=none) 
					x2axisopts=(display=none griddisplay=off displaySecondary=none);
					AxisTable Value=atrisk X=tatrisk /class=Attr_trtname 
						ValueAttrs=( Color=black size=9 ) display=(values)
						headerlabel= "Number of subjects at risk"
						headerlabelattrs=(size=10) valuehalign=center;
					drawtext textattrs=( size=9pt) "grp1" /anchor=bottomleft 
						width=18 widthunit=percent 
						xspace=wallpercent yspace=wallpercent x=5 y=30 justify=center 
					;
					drawtext textattrs=( size=9pt) "grp2"
						/anchor=bottomleft width=15 widthunit=percent 
						xspace=wallpercent yspace=wallpercent x=5 y=5
						justify=center;
				endlayout;
			endlayout;
		endgraph;
	end;
run;

proc sgrender data=survivalplot  template=km2;
run;
