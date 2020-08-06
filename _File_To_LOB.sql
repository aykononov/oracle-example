/* Загрузка данных из файла в LOB */

DECLARE

  l_ServDir VARCHAR2(4000) := 'TEMP'; -- объект директории на сервере
  l_FileName VARCHAR2(200) := 'test.txt'; -- загружаемый файл
  l_blob  BLOB;
  l_clob  CLOB;
  l_bfile BFILE;

BEGIN
  
  -- создаем в таблице строку, устанавливаем столбцы BLOB и CLOB в
  -- EMPTY_BLOB(), EMPTY_CLOB() и извлекаем их значения в одном вызове.
  INSERT INTO SCOTT.TABL
  VALUES (1, l_FileName, EMPTY_BLOB(), EMPTY_CLOB())
  RETURNING File_Blob, File_Clob INTO l_blob, l_clob;
  
  -- создаем объект BFILE
  l_bfile := bfilename(l_ServDir, l_FileName);
  -- открываем объект LOВ
  dbms_lob.fileopen(l_bfile);
  -- загружаем все содержимое файла в локатор LOB
  -- dbms_lob.getlength(l_bfile) количество байтов BFILE, подлежащих загрузке (все байты)
  dbms_lob.loadfromfile(l_blob, l_bfile, dbms_lob.getlength(l_bfile));
  -- закрываем открытый ранее файл BFILE, и столбец BLOB загружен
  dbms_lob.fileclose(l_bfile);

  l_bfile := bfilename(l_ServDir, l_FileName);
  dbms_lob.fileopen(l_bfile);
  dbms_lob.loadfromfile(l_clob, l_bfile, dbms_lob.getlength(l_bfile));
  dbms_lob.fileclose(l_bfile);
  
  COMMIT;

END;
