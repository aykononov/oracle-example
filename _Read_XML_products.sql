--Читаем файл products.xml из директории БД 'DIRECTORY_DB'

SELECT t.extract('File/Size/text()').getStringVal()         AS "SIZE",
       t.extract('File/FileName/text()').getStringVal()     AS FileName,
       t.extract('File/Language/text()').getStringVal()     AS Lang,
             t.extract('File/Edition/text()').getStringVal()      AS Edition,
             t.extract('File/Architecture/text()').getStringVal() AS Arc,
             t.extract('File/FilePath/text()').getStringVal()     AS FilePath
  FROM TABLE(XMLSEQUENCE(XMLTYPE(bfilename('DIRECTORY_DB','products.xml'),nls_charset_id('AL32UTF8')).extract('//Files//File'))) t
 WHERE t.extract('File/Language/text()').getStringVal() = 'Russian (Russia)';
