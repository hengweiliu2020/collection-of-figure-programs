%macro split(invar=, prefix=, cnt=);

 

data val (drop=_: i);

  set val;

  length &prefix.1-&prefix.&cnt $200;

  array &prefix[&cnt] $200 &prefix.1-&prefix.&cnt;

  _copy = &invar;

 

  do part = 1 to &cnt while (length(_copy) > 0);

    if length(_copy) <= 200 then do;

      &prefix.[part] = _copy;

      _copy = '';

    end;

    else do;

     

      i = findc(substr(_copy,1,200), ' ', 'b');

      if i = 0 then i = 200;

      &prefix.[part] = substr(_copy, 1, i);

      _copy = substr(_copy, i);

    end;

  end;

 

run;

 

%mend;