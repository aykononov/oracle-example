/* Загрузка данных из файла в CLOB с перекодировкой из UTF8 в кодировку БД */

DECLARE
  l_ServDir VARCHAR2(4000) := 'TEMP'; -- объект директории на сервере
  l_FileName VARCHAR2(200) := 'test.txt'; -- загружаемый файл
  l_clob  CLOB;
  l_bfile BFILE;
  
  l_dest_offset   INTEGER := 1;
  l_src_offset    INTEGER := 1;
  l_src_csid      NUMBER  := NLS_CHARSET_ID('UTF8'); -- кодировка файла
  l_lang_context  NUMBER  := dbms_lob.default_lang_ctx;
  l_warning       INTEGER;
BEGIN
  INSERT INTO SCOTT.TABL
  VALUES (1, l_FileName, empty_clob())
  RETURNING File_Clob INTO l_clob;

        l_bfile := bfilename(l_ServDir, l_FileName);
        dbms_lob.fileopen(l_bfile);       
        dbms_lob.LoadCLOBfromFile( dest_lob     => l_clob
                                  ,src_bfile    => l_bfile
                                  ,amount       => dbms_lob.getlength(l_bfile)
                                  ,dest_offset  => l_dest_offset
                                  ,src_offset   => l_src_offset
                                  ,bfile_csid   => l_src_csid
                                  ,lang_context => l_lang_context
                                  ,warning      => l_warning);
        dbms_lob.close(l_bfile);
        COMMIT;
END;

SELECT dbms_lob.getlength(File_Clob), File_Clob from SCOTT.TABL ; 

DBMS_LOB.GETLENGTH(FILE_CLOB) FILE_CLOB
----------------------------  ---------
                        10150 <CLOB>
