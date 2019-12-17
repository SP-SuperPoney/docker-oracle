--&1=$ORACLE_BASE
--&2=$ORACLE_SID

--FSV
CREATE SMALLFILE TABLESPACE fsvdata LOGGING 
DATAFILE '&1/oradata/&2/fsvdata01.dbf' SIZE 1M REUSE AUTOEXTEND ON NEXT 1M
MAXSIZE UNLIMITED EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

CREATE SMALLFILE TABLESPACE fsvindex LOGGING 
DATAFILE '&1/oradata/&2/fsvindex01.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M
MAXSIZE UNLIMITED EXTENT MANAGEMENT LOCAL 
SEGMENT SPACE MANAGEMENT AUTO;

--SYOTOS
CREATE SMALLFILE TABLESPACE syotosdata LOGGING 
DATAFILE '&1/oradata/&2/syotosdata01.dbf' SIZE 1M REUSE AUTOEXTEND ON NEXT 1M
MAXSIZE UNLIMITED EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

CREATE SMALLFILE TABLESPACE syotosindex LOGGING 
DATAFILE '&1/oradata/&2/syotosindex01.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M
MAXSIZE UNLIMITED EXTENT MANAGEMENT LOCAL 
SEGMENT SPACE MANAGEMENT AUTO;

--DESMOS
CREATE SMALLFILE TABLESPACE desmosdata LOGGING 
DATAFILE '&1/oradata/&2/desmosdata01.dbf' SIZE 1M REUSE AUTOEXTEND ON NEXT 1M
MAXSIZE UNLIMITED EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

CREATE SMALLFILE TABLESPACE desmosindex LOGGING 
DATAFILE '&1/oradata/&2/desmosindex01.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M
MAXSIZE UNLIMITED EXTENT MANAGEMENT LOCAL 
SEGMENT SPACE MANAGEMENT AUTO;

--MUNERIS
CREATE SMALLFILE TABLESPACE munerisdata LOGGING 
DATAFILE '&1/oradata/&2/munerisdata01.dbf' SIZE 1M REUSE AUTOEXTEND ON NEXT 1M
MAXSIZE UNLIMITED EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

CREATE SMALLFILE TABLESPACE munerisindex LOGGING 
DATAFILE '&1/oradata/&2/munerisindex01.dbf' SIZE 1M AUTOEXTEND ON NEXT 1M
MAXSIZE UNLIMITED EXTENT MANAGEMENT LOCAL 
SEGMENT SPACE MANAGEMENT AUTO;

exit;