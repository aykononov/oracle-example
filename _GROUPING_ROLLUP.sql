SELECT DECODE(GROUPING(deptno), 0, to_char(deptno), 'Total') AS deptno,
       COUNT(*) AS cnt
  FROM SCOTT.EMP
 GROUP BY ROLLUP(deptno);

-------------------------
DEPTNO	 CNT
10	   3
20	   5
30	   6
Total	  14
