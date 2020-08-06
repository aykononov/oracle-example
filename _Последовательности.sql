/* Создать новую последовтельность */
CREATE SEQUENCE SCOTT.NEW_SEQ
MINVALUE     1
START WITH   1
INCREMENT BY 1
NOCACHE;

/* Использование последовательности */
SELECT SCOTT.NEW_SEQ.NEXTVAL, SCOTT.NEW_SEQ..CURRVAL from dual;

/* Как получить значение сиквенса(SEQUENCE) в процедуре */
create or replace procedure Get_Seq_nextValue (p_seq_name VARCHAR2) 
IS
  l_nextValue NUMBER;
  l_sqlstr VARCHAR2(128);
BEGIN
  l_sqlstr := 'select '||p_seq_name||'.nextval from dual';
  EXECUTE IMMEDIATE l_sqlstr INTO l_nextvalue;
  DBMS_OUTPUT.put_line(l_nextvalue);
end Get_Seq_nextValue;
