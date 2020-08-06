SELECT regexp_substr('C:\Temp\textxml.v.xml','\.[^.]+$') AS c1
       ,regexp_substr('C:\Temp\textxml.b.v.xml','\..+') AS c2
       ,regexp_substr('C:\Temp\textxml.xml','([^\])+\.[^.]+$') AS c3
  FROM dual;
