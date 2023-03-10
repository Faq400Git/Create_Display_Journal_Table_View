--- Let's test the Stored Procedure CREATE_DISPLAY_JOURNAL_TABLE_VIEW with this example

-- Let's create a sample Library (with the default Journal and so on)
create schema FAQ400JOU;

-- Let's create a sample table
create or replace table FAQ400JOU.MYSAMPLETABLE(
id int GENERATED ALWAYS AS IDENTITY,
Field1Char CHAR(15) NOT NULL DEFAULT ' ',
Field2VarChar  VARCHAR(300) NOT NULL DEFAULT ' ',
Field3Numeric  NUMERIC(15, 4) NOT NULL DEFAULT 0,
Field4Decimal  DECIMAL(21, 6) NOT NULL DEFAULT 0,
Field5Integer  INTEGER NOT NULL DEFAULT 0,
Field6SmallInt SMALLINT NOT NULL DEFAULT 0,
Field5BigInt  BIGINT NOT NULL DEFAULT 0,
Field6DecFloat  DECFLOAT NOT NULL DEFAULT 0,
Field7Real  REAL NOT NULL DEFAULT 0,
Field8Double  DOUBLE NOT NULL DEFAULT 0,
Field9Date   DATE NOT NULL DEFAULT  CURRENT DATE,
Filed10Time  TIME NOT NULL DEFAULT CURRENT TIME,
Field11Timestamp  TIMESTAMP NOT NULL DEFAULT CURRENT TIMESTAMP);

-- Insert some CHAR and VARCHAR data
insert into FAQ400JOU.MYSAMPLETABLE (Field1Char, Field2VarChar)
values('TEST01', 'This is only a sample string in a varchar field');

-- Insert some NUMBERS
insert into FAQ400JOU.MYSAMPLETABLE (Field3Numeric, Field4Decimal, Field5Integer, Field6SmallInt, Field5BigInt, Field6DecFloat, Field7Real, Field8Double )
values(123.45 , 67.890 , 2147483647 ,  32767 , 9223372036854775807, 9999999.88888, 8888888.77777, 6666666666666.555);

-- Insert some DATE and TIME
insert into FAQ400JOU.MYSAMPLETABLE (Field9Date, Filed10Time, Field11Timestamp)
values(current date, current time, current timestamp);

insert into FAQ400JOU.MYSAMPLETABLE (Field9Date, Filed10Time, Field11Timestamp)
values('2023-01-31', '09:00:00', '2023-01-31 09:00:00');

-- Now simulating an update
update FAQ400JOU.MYSAMPLETABLE set field2varchar='This is my change'
where field1char='TEST01';

-- And delete a row
delete from FAQ400JOU.MYSAMPLETABLE
where field1char='TEST01';


--Let's create a Gloabl Variable to get the output string
create variable FAQ400.GV_VARCHAR  VARCHAR(32000);
call FAQ400.CREATE_DISPLAY_JOURNAL_TABLE_VIEW('FAQ400JOU', 'MYSAMPLETABLE', 'FAQ400JOU', 'QSQJRN', 'FAQ400JOU', 'V_MYSAMPLETABLE_AUDIT', 'Y', FAQ400.GV_VARCHAR);

-- We can view the SQL Statement for the view
select FAQ400.GV_VARCHAR FROM SYSIBM.SYSDUMMY1;

-- And check the view with journal entries and data
select * from FAQ400JOU.V_MYSAMPLETABLE_AUDIT;
