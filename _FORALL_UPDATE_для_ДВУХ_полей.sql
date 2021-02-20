/*
Из таблицы CSC_TYPE_STREET поле vt_id (со всеми id-шниками) перенести в таблицу CSC_ADDRESS в поле vt_id
*/

-- самый простой способ
BEGIN
  FOR i IN (SELECT tst.id, tst.vt_id
              FROM CSC_TYPE_STREET   tst
             WHERE tst.vt_id IS NOT NULL)
  LOOP
    UPDATE CSC_ADDRESS adr SET adr.vt_id = i.vt_id WHERE adr.tst_id = i.id;
  END LOOP;
END;

-- с использованием MERGE
MERGE INTO CSC_ADDRESS adr
USING (SELECT tst.id, tst.vt_id
         FROM CSC_TYPE_STREET tst
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
