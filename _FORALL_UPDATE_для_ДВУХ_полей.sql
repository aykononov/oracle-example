/*
Из таблицы CSC_TYPE_STREET поле vt_id (со всеми id-шниками) перенести в таблицу CSC_ADDRESS в поле vt_id
*/

-- самый простой способ
BEGIN
  FOR i IN (SELECT tst.id, tst.vt_id
              FROM CSC_TYPE_STREET   tst -- "Источник"
             WHERE tst.vt_id IS NOT NULL)
  LOOP
    -- "Целевая"
    UPDATE CSC_ADDRESS adr SET adr.vt_id = i.vt_id WHERE adr.tst_id = i.id;
  END LOOP;
END;

-- с использованием MERGE
MERGE INTO CSC_ADDRESS adr -- "Целевая"
USING (SELECT tst.id, tst.vt_id
         FROM CSC_TYPE_STREET tst -- "Источник"
        WHERE tst.vt_id IS NOT NULL) t
ON (adr.tst_id = t.id)
WHEN MATCHED THEN
  UPDATE SET adr.vt_id = t.vt_id
WHEN NOT MATCHED THEN
  INSERT (adr.vt_id) VALUES (t.vt_id);


-- с применением Коллекций и FORALL
DECLARE
  TYPE VT_ID_R IS RECORD (tst_id NUMBER, vt_id NUMBER);
  TYPE VT_ID_T IS TABLE OF VT_ID_R INDEX BY PLS_INTEGER;
  l_vt_id VT_ID_T;

BEGIN
  -- "Источник"
  SELECT tst.id, tst.vt_id BULK COLLECT
    INTO l_vt_id
    FROM CSC_TYPE_STREET  tst 
   WHERE tst.vt_id IS NOT NULL;

   -- "Целевая"
   FORALL i IN 1..l_vt_id.count SAVE EXCEPTIONS
   UPDATE CSC_ADDRESS adr
      SET adr.vt_id  = l_vt_id(i).vt_id
    WHERE adr.tst_id = l_vt_id(i).tst_id;
	 
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line(sqlerrm);
      dbms_output.put_line('Number of ERRORS: ' || SQL%BULK_EXCEPTIONS.COUNT);
   FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
      dbms_output.put_line('Error ' || i || ' occurred during iteration ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
      dbms_output.put_line('Oracle error is ' ||SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
   END LOOP; 

END;

--- В одной таблице нужно обновить в одном столбце дату из другого столбца с датой + 1 день
DECLARE
    TYPE CLOSE_FIX_DATE_R IS RECORD(t_id DB_LOAN_PRODUCT.id%TYPE, r_value DB_LOAN_PRODUCT_PARAM.value%TYPE);
    TYPE CLOSE_FIX_DATE_T IS TABLE OF CLOSE_FIX_DATE_R INDEX BY PLS_INTEGER;
    l_cfd CLOSE_FIX_DATE_T;

BEGIN
    SELECT T.id, R.value
      BULK COLLECT
      INTO l_cfd
      FROM DB_LOAN_PRODUCT T, DB_LOAN_PRODUCT_PARAM R
     WHERE T.state NOT IN
           ('DELIVERED', 'WAITING_DELIVERY', 'WAITING_PAY_INSURANCE', 'PAY_INSURANCE_COMPLETE', 'COMPLETE_WITHOUT_INSURANCE')
       AND T.id = R.product_id
       AND R.name = 'CLOSE_FIX_DATE'
       AND T.update_date IS NULL
       AND T.product_type = 'CREDIT_CARD'
       AND TO_DATE(R.value, 'dd.MM.yyyy') < SYSDATE
       AND ROWNUM <= 2500;

    FORALL i IN 1 .. l_cfd.count SAVE EXCEPTIONS
        UPDATE DB_LOAN_PRODUCT P
           SET P.update_date = TO_DATE(l_cfd(i).r_value) + 1
         WHERE P.id = l_cfd(i).t_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;

    WHEN OTHERS THEN
        dbms_output.put_line(SQLERRM);
        dbms_output.put_line('Number of ERRORS: ' || SQL%BULK_EXCEPTIONS.COUNT);
        FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
            LOOP
                dbms_output.put_line('Error ' || i || ' occurred during iteration ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
                dbms_output.put_line('Oracle error is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
            END LOOP;
END;

