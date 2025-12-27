* author: Hengwei Liu; 
* display a table below a figure;
* 2023-10-14; 

proc print data=sashelp.class;
run;

data class; set sashelp.class; 
lx1=1;
lx2=2;
agec=strip(put(age, best.)); 

proc format;
value xaxisf
1="Sex"
2="Age"
;

proc template;
  define statgraph bar_plot;
    begingraph /designwidth = 8.4in designheight = 4.8in;

 layout lattice / columndatarange=union rowweights=(0.7 0.3) rowgutter=0 rows=2;

layout overlay/xaxisopts=(display=none); 
barchart y=height category=name;
endlayout;

layout overlay/yaxisopts=(griddisplay=off tickvalueattrs=(size=7pt weight=bold) display=(tickvalues ticks line) 
               linearopts=(tickvaluesequence=(start=1 end=2 increment=1) viewmin=1 viewmax=2)) walldisplay=none;
textplot x=name y=lx1 text=sex;
textplot x=name y=lx2 text=agec;

endlayout;
 endlayout;
  endgraph;
  end;

run;

proc sgrender data=class template=bar_plot;
format lx1 lx2 xaxisf.; 
run;




