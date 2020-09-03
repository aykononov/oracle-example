DECLARE
  TYPE EMPNO_T IS TABLE OF SCOTT.EMP.empno%TYPE 
    INDEX BY PLS_INTEGER;
  TYPE SAL_T   IS TABLE OF SCOTT.EMP.sal%TYPE;

  l_empno EMPNO_T;
  l_sal SAL_T;

CURSOR emp_cur IS 	
SELECT empno, sal 
  FROM SCOTT.EMP;

BEGIN
	 OPEN emp_cur;
	FETCH emp_cur BULK COLLECT 
	 INTO l_empno, l_sal;
	CLOSE emp_cur;

  FORALL i IN 1..l_empno.COUNT SAVE EXCEPTIONS  
	 MERGE INTO SCOTT.EMP1 e1
	 USING SCOTT.EMP e
      ON (e1.empno = e.empno)
	  WHEN MATCHED THEN
  UPDATE SET e1.sal = l_sal(i) + (l_sal(i) * .01);

  FORALL i IN 1..l_empno.COUNT SAVE EXCEPTIONS  
   MERGE INTO SCOTT.EMP2 e2
   USING SCOTT.EMP e
      ON (e2.empno = e.empno)
    WHEN MATCHED THEN
  UPDATE SET e2.sal = l_sal(i) + (l_sal(i) / .02); -- здесь будут ОШИБКИ!!!

COMMIT;  

EXCEPTION
   WHEN OTHERS THEN
   dbms_output.put_line(sqlerrm);
   dbms_output.put_line('Number of ERRORS: ' || SQL%BULK_EXCEPTIONS.COUNT);
   FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
      dbms_output.put_line('Error ' || i || ' occurred during iteration ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
      dbms_output.put_line('Oracle error is ' ||SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
    END LOOP; 
ROLLBACK;
                                                        
END;
