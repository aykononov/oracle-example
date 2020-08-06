/* Разбор XML средствами Oracle. */

-- Пример создания экземпляра XMLType, с содержимым, передаваемым в строке
SELECT XMLType('<hello-world>
                  <word seq="1">Hello</word>
                  <word seq="2">world</word>
                </hello-world>') xml
  FROM dual;

-- Выбираем фрагменты XML
SELECT  t.xml.extract('//word')                AS c1
       ,t.xml.extract('//word[position()=1]')  AS c2
       ,t.xml.extract('//word[@seq=2]/text()') AS c3
  FROM (
        SELECT XMLType('<hello-world>
                  <word seq="1">Hello</word>
                  <word seq="2">world</word>
                </hello-world>') xml
          FROM dual
        )t;
        
     C1                        C2                          C3
----------------------------  --------------------------  -----
  <word seq="1">Hello</word>  <word seq="1">Hello</word>  world
  <word seq="2">world</word>


SELECT extractValue(t.xml, 'a') case1,
       extractValue(t.xml, 'a', 'xmlns="foo"') case2,
       extractValue(t.xml, 'y:a/@z:val', 'xmlns:y="foo" xmlns:z="bar"') case3
  FROM (SELECT XMLType('<a xmlns="foo" xmlns:x="bar" x:val="a-val">a-text</a>') XML
	        FROM dual) t;

   	CASE1	 CASE2	 CASE3
---------  ------  -----
1		       a-text	 a-val


SELECT d.extract('//ENTITY//ATTRIBUTE[@name="SURNAME"]/@value').getStringVal() surname
  FROM TABLE(XMLSequence(XMLType('<?xml version="1.0" encoding="windows-1257" ?>
<RESPONSE>
  <DATA REQUEST_ID="111">
    <ENTITY name="PACKAGE_001">
      <ATTRIBUTE name="PERS_ID" value="1111" />
      <ATTRIBUTE name="FIRST_NAME" value="OLGA" />
      <ATTRIBUTE name="SURNAME" value="NOVIKOVA" />
    </ENTITY>
    <ENTITY name="PACKAGE_001">
      <ATTRIBUTE name="PERS_ID" value="2222" />
      <ATTRIBUTE name="FIRST_NAME" value="ANNA" />
      <ATTRIBUTE name="SURNAME" value="ANTONOVA" />
    </ENTITY>
  </DATA>
</RESPONSE>').extract('RESPONSE/DATA/ENTITY'))) d;

   SURNAME
-----------
1	 NOVIKOVA
2	 ANTONOVA


SELECT t.extract('File/FileName/text()').getStringVal()     AS FileName,
       t.extract('File/Language/text()').getStringVal()     AS Lang,
			 t.extract('File/Edition/text()').getStringVal()      AS Edition,
			 t.extract('File/Architecture/text()').getStringVal() AS Arc,
 			 t.extract('File/FilePath/text()').getStringVal()     AS FilePath
  FROM TABLE(XMLSequence(XMLType('<?xml version="1.0" encoding="UTF-8"?>
<PublishedMedia id="" release="">
  <Files>
    <File id="">
      <FileName>19041.264.200511-0456.vb_release_svc_refresh_CLIENTCHINA_RET_x64FRE_zh-cn.esd</FileName>
      <LanguageCode>zh-cn</LanguageCode>
      <Language>Chinese (Simplified, China)</Language>
      <Edition>CoreCountrySpecific</Edition>
      <Architecture>x64</Architecture>
      <Size>3328489790</Size>
      <Sha1>9850a242614394de2fdc10f6d321c3b866d9acfd</Sha1>
      <FilePath>http://dl.delivery.mp.microsoft.com/filestreamingservice/files/050055a3-481a-42b6-b5d7-a74b00aa6991/19041.264.200511-0456.vb_release_svc_refresh_CLIENTCHINA_RET_x64FRE_zh-cn.esd</FilePath>
      <Key />
      <Architecture_Loc>%ARCH_64%</Architecture_Loc>
      <Edition_Loc>%BASE_CHINA%</Edition_Loc>
      <IsRetailOnly>False</IsRetailOnly>
    </File>
	</Files>
</PublishedMedia>').extract('//Files//File'))) t;


-- Парсинг файла /IN2DB/products.xml (кодировки AL32UTF8, CL8MSWIN1251)
SELECT t.extract('File/FileName/text()').getStringVal()     AS FileName,
       t.extract('File/Language/text()').getStringVal()     AS Lang,
			 t.extract('File/Edition/text()').getStringVal()      AS Edition,
			 t.extract('File/Architecture/text()').getStringVal() AS Arc,
 			 t.extract('File/FilePath/text()').getStringVal()     AS FilePath
  FROM TABLE(XMLSEQUENCE(XMLTYPE(bfilename('IN2DB','products.xml'),nls_charset_id('AL32UTF8')).extract('//Files//File'))) t;


/* Создание и инициализация LOB */
DECLARE
   l_clob CLOB;
BEGIN
   IF l_clob IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('Сначала l_clob IS NULL;');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Сначала l_clob IS NOT NULL;');
   END IF;
   DBMS_OUTPUT.PUT_LINE('Длина l_clob = ' || DBMS_LOB.GETLENGTH(l_clob));
   -- инициализация переменной LOB
   l_clob := EMPTY_CLOB();
   IF l_clob IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('После инициализации l_clob IS NULL;');
   ELSE
      DBMS_OUTPUT.PUT_LINE('После инициализации l_clob IS NOT NULL;');
   END IF;
   DBMS_OUTPUT.PUT_LINE('Длина l_clob = ' || DBMS_LOB.GETLENGTH(l_clob));
END;
-----------------------
Сначала l_clob IS NULL;
Длина l_clob = ;
После инициализации l_clob IS NOT NULL;
Длина l_clob = 0;


/* Читаем первую строку из файла */
DECLARE
   l_file UTL_FILE.FILE_TYPE; 
   l_line VARCHAR2(32767);
BEGIN
   l_file := UTL_FILE.FOPEN ('IN2DB', 'test.xml', 'R', max_linesize => 32767);
   UTL_FILE.GET_LINE (l_file, l_line);
   DBMS_OUTPUT.PUT_LINE (l_line);
END;

/* Читает каждую строку из файла */
DECLARE
   l_file UTL_FILE.file_type; 
   l_line VARCHAR2 (32767);
BEGIN
   l_file := UTL_FILE.FOPEN ('IN2DB', 'test.xml', 'R');
   LOOP
      UTL_FILE.get_line (l_file, l_line); 
      --process_line (l_line);
      DBMS_OUTPUT.PUT_LINE (l_line);
   END LOOP;
EXCEPTION
   WHEN NO_DATA_FOUND 
   THEN
      UTL_FILE.fclose (l_file);
END;

DECLARE
  PROCEDURE gen_utl_file_dir_entries
  IS
  BEGIN
     FOR rec IN (SELECT * FROM all_directories)
     LOOP
        DBMS_OUTPUT.PUT_LINE ('UTL_FILE_DIR = ' || rec.directory_path);
     END LOOP;
  END gen_utl_file_dir_entries;
BEGIN
  gen_utl_file_dir_entries;
END;
-----------------------------------
UTL_FILE_DIR = /u02/smbshares/IN2DB
