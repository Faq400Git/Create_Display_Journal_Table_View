---------------------------------------------------------------------------------------------------
-- FAQ400.CREATE_DISPLAY_JOURNAL_TABLE_VIEW 
-- Author : Roberto De Pedrini (FAQ400)
--  https://github.com/Faq400Git/CREATE_DISPLAY_JOURNAL_TABLE_VIEW
--
-- SQL Stored Procedure to read data from Journal Entries, interpreting data from the DATA_ENTRY
--     storage buffer
--
-- This SP create (or replace) a view for your Table or Phisical File under Journal Control
-- reading columns and type from the Catalog SYSCOLUMNS.
-- Pay attention for fields with data type DATE/TIME/TIMESTAMP ... the storage area in the
-- journal is not the same as shown in the Catalog SYSCOLUMNS!
--
------------------------------------------------------------------------------------------------


CREATE OR REPLACE PROCEDURE FAQ400.CREATE_DISPLAY_JOURNAL_TABLE_VIEW  ( IN MYTABLE_LIBRARY   varchar(100),
                                                        IN MYTABLE_NAME      varchar(100),
                                                        IN MYJOURNAL_LIBRARY varchar(100),
                                                        IN MYJOURNAL_NAME    varchar(100),
                                                        IN MYVIEW_LIBRARY    varchar(100),
                                                        IN MYVIEW_NAME       varchar(100),
                                                        IN CREATEANDREPLACE  char(1),
                                                        OUT MYCMD            varchar(32000)
                                                        )
LANGUAGE SQL
SPECIFIC FAQ400/CRTJOUVIEW
SET OPTION DBGVIEW=*SOURCE
P1: BEGIN

DECLARE STRINGPOSITION, REALSTORAGE  INTEGER;
DECLARE COLUMN_NAME, COLUMN_HEADING, DATA_TYPE  CHAR(100);
DECLARE ORDINAL_POSITION, FIELD_LENGTH, NUMERIC_SCALE, STORAGE, FIELD_CCSID  DECIMAL(15, 0);
DECLARE END_TABLE  INT DEFAULT 0;
DECLARE MY_SYSTEM_TABLE_NAME, MY_SYSTEM_SCHEMA_NAME CHAR(10); -- QSYS2.DISPLAY_JOURNAL need SYSTEM table/schema nale

DECLARE cursor1 CURSOR FOR
   select column_name, column_heading, ordinal_position, data_type, length, coalesce(numeric_scale, 0), storage, coalesce(ccsid, 0)
    from  SYSCOLUMNS a
    WHERE (SYSTEM_TABLE_NAME = MYTABLE_NAME OR TABLE_NAME = MYTABLE_NAME)
              AND (SYSTEM_TABLE_SCHEMA = MYTABLE_LIBRARY OR TABLE_SCHEMA= MYTABLE_LIBRARY)
              ORDER BY ORDINAL_POSITION;
              
DECLARE CONTINUE HANDLER FOR NOT FOUND
 SET END_TABLE = 1;                

SET MYCMD='';

-- Retrieve SYSTEM TABLE and SCHEMA name (you can call this procedure passing SQL Table Name o System Table Name
 SELECT  system_table_name, system_table_schema
 INTO  MY_SYSTEM_TABLE_NAME, MY_SYSTEM_SCHEMA_NAME
 FROM QSYS2.SYSTABLES
 WHERE (SYSTEM_TABLE_NAME = MYTABLE_NAME OR TABLE_NAME = MYTABLE_NAME)
              AND (SYSTEM_TABLE_SCHEMA = MYTABLE_LIBRARY OR TABLE_SCHEMA= MYTABLE_LIBRARY);
              

-- Create MYCMD string for the CREATE VIEW command
IF CREATEANDREPLACE='Y' THEN
    SET MYCMD='CREATE OR REPLACE VIEW '; 
ELSE
    SET MYCMD='CREATE VIEW '; 
END IF;    
    
SET MYCMD=TRIM(MYCMD) concat ' ' concat
TRIM(MYVIEW_LIBRARY) concat
'.' concat
TRIM(MYVIEW_NAME) concat
' AS (' concat 
'SELECT ENTRY_TIMESTAMP ,
                    JOURNAL_CODE ,
                    CASE WHEN JOURNAL_ENTRY_TYPE = ''PT''
                           THEN ''INSERT''
                         WHEN JOURNAL_ENTRY_TYPE = ''PX''
                           THEN ''INSERT BY RRN''
                         WHEN JOURNAL_ENTRY_TYPE = ''UB''
                           THEN ''UPDATE BEFORE''
                         WHEN JOURNAL_ENTRY_TYPE = ''UP''
                           THEN ''UPDATE AFTER''
                         WHEN JOURNAL_ENTRY_TYPE = ''DL''
                           THEN ''DELETE''
                         ELSE JOURNAL_ENTRY_TYPE
                    END AS JRNTYPE,
                    JOB_NAME,
                    JOB_USER,
                    CURRENT_USER as CURRENTUSER,
                    JOB_NUMBER ,
                    SUBSTR(OBJECT,1,10) AS FILE,
                    SUBSTR(OBJECT,11,10) AS FILELIB,
                    SUBSTR(OBJECT,21,10) AS FILEMBR,
                    OBJECT_TYPE,
                    PROGRAM_NAME ,
                    PROGRAM_LIBRARY ';
-- Read all table columns from SYSCOLUMS catalog                    

SET STRINGPOSITION=1; 


   OPEN cursor1;
   FETCH FROM cursor1 INTO COLUMN_NAME, COLUMN_HEADING, ORDINAL_POSITION, DATA_TYPE, FIELD_LENGTH, NUMERIC_SCALE, STORAGE, FIELD_CCSID;
   
   WHILE END_TABLE = 0  DO  
   
      -- Set the REALSTORAGE length considering case for DATE/TIME/TIMESTAMT different from STORAGE in the SYSCOMUMNS (Why??)
      CASE 
       WHEN DATA_TYPE='DATE'     THEN  SET REALSTORAGE=10;
       WHEN DATA_TYPE='TIME'     THEN  SET REALSTORAGE=08;
       WHEN DATA_TYPE='TIMESTMP' THEN  SET REALSTORAGE=26;
                                 ELSE  SET REALSTORAGE=STORAGE;
      END CASE;                           
      -- INTERPRET for each data_type (Pay attention, some DATA_TYPE are stored in the journal ENTRY_DATA in a different way:
      -- DATA as CHAR(10), TIME as CHAR(8), TIMESTAMP as CHAR(26)  
      SET MYCMD= trim(MYCMD) concat
      ' , INTERPRET(SUBSTR(ENTRY_DATA ,' concat
      trim(cast(STRINGPOSITION as CHAR(10))) concat
      ' , ' concat
      trim(cast(REALSTORAGE as CHAR(10))) concat
      ') AS ' concat
      trim(CASE WHEN DATA_TYPE='DATE' THEN 'CHAR(10)'
                WHEN DATA_TYPE='TIME' THEN 'CHAR(08)'
                WHEN DATA_TYPE='TIMESTMP' THEN 'CHAR(26)'
                WHEN DATA_TYPE='FLOAT' AND FIELD_LENGTH=16 THEN 'FLOAT'
                WHEN DATA_TYPE='FLOAT' AND FIELD_LENGTH=8 THEN 'DOUBLE'
                WHEN DATA_TYPE='FLOAT' AND FIELD_LENGTH=4 THEN 'REAL'
                ELSE DATA_TYPE END);
      case 
           when DATA_TYPE = 'CHAR' OR
                DATA_TYPE = 'VARCHAR' OR
                DATA_TYPE = 'BINARY' 
                  THEN SET MYCMD=TRIM(MYCMD) CONCAT ' (' concat trim(cast(FIELD_LENGTH as CHAR(10))) concat ')) '   ; 
           when DATA_TYPE = 'DECIMAL' OR 
                DATA_TYPE = 'NUMERIC' 
                  THEN SET MYCMD=TRIM(MYCMD) CONCAT  ' (' concat trim(cast(FIELD_LENGTH as CHAR(10))) concat ' , ' concat trim(cast(numeric_scale as CHAR(10)))concat '))' ; 
            ELSE  
                 SET MYCMD= TRIM(MYCMD) concat ')'  ;

           END CASE;
       
      -- FIELD NAME     
      SET MYCMD=TRIM(MYCMD) CONCAT     
      ' AS ' concat
      TRIM(COLUMN_NAME);
      
   
                
      SET STRINGPOSITION = STRINGPOSITION+REALSTORAGE;
      
      FETCH FROM cursor1 INTO COLUMN_NAME, COLUMN_HEADING, ORDINAL_POSITION, DATA_TYPE, FIELD_LENGTH, NUMERIC_SCALE, STORAGE, FIELD_CCSID;
   END WHILE;
   CLOSE cursor1;
   SET MYCMD= TRIM(MYCMD) CONCAT
   ' FROM TABLE(DISPLAY_JOURNAL(' CONCAT
   ' JOURNAL_LIBRARY  => ''' CONCAT MYJOURNAL_LIBRARY CONCAT '''' CONCAT
   ' ,JOURNAL_NAME    => ''' CONCAT MYJOURNAL_NAME CONCAT '''' CONCAT
   ' ,STARTING_RECEIVER_NAME =>  ''*CURAVLCHN'' ' CONCAT
   ' ,JOURNAL_CODES   => ''R'' ' CONCAT
   ' ,OBJECT_LIBRARY  => ''' CONCAT MY_SYSTEM_SCHEMA_NAME CONCAT '''' CONCAT 
   ' ,OBJECT_NAME     => ''' CONCAT MY_SYSTEM_TABLE_NAME  CONCAT '''' CONCAT
   ' ,OBJECT_MEMBER   => ''*ALL'' ' CONCAT
   ' ,OBJECT_OBJTYPE  => ''*FILE'' )))';
   
   -- Run this SQL Statement and create the view
   Execute Immediate MYCMD; 

                
END P1;




---------------------------------------------------------
-- Hw to call the Stored Procedure 
---------------------------------------------------------

-- 1 If you want call the SP from and SQL Script you need a Global Variable to store the SQL Statement created and used in the SP

create variable MYDATALIB.MY_GLOBAL_VARIABLE  VARCHAR(32000);

-- 2 Now you can call the SP to create your View fro Your Table and Your Journal

call FAQ400.CREATE_DISPLAY_JOURNAL_TABLE_VIEW('MYDATALIB', 'MYTABLE', 'MYJOURNLIB', 'MYJOURNAL', 'MYDATALIB', 'MYVIEW', 'Y', MYDATALIB.MY_GLOBAL_VARIABLE);

-- 3 Check the SQL Statment used to create the VIEW

SELECT  MYDATALIB.MY_GLOBAL_VARIABLE from SYSIBM.SYSDUMMY1;

-- 4 Check the view and journal entries
SELECT * FROM MYDATALIB.MYVIEW;

