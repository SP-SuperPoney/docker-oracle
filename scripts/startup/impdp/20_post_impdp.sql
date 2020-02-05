set feedback off verify off heading off pagesize 0 newpage 0 trimspool on linesize 2000;
set serveroutput on size 1000000;

PROMPT Post impdp script
PROMPT Customize to : change passwords, apply patches, ...

PROMPT Compile invalid objects
DECLARE 
    CURSOR C_OBJ_INVALID IS
        SELECT *
        FROM   ALL_OBJECTS
        WHERE STATUS = 'INVALID'
        AND OWNER not in ('SYSMAN','PERFSTAT','CHEOPSSYSDBA', 'SYS', 'SYSTEM', 'PUBLIC', 'WMSYS', 'APEX_030200', 'JAU');


    CURSOR C_OBJ_ERROR(p_owner VARCHAR2, p_name VARCHAR2) IS
        SELECT *
        FROM   ALL_ERRORS
        WHERE OWNER = p_owner
        AND NAME = p_name
        ORDER BY owner, name, type, sequence;

    v_error VARCHAR2(4096);
BEGIN
    FOR REC_OBJ IN C_OBJ_INVALID LOOP
        BEGIN
          if REC_OBJ.OBJECT_TYPE = 'PACKAGE BODY' then 
            EXECUTE IMMEDIATE 'alter ' || REC_OBJ.OBJECT_TYPE || ' ' || REC_OBJ.OWNER || '.' || REC_OBJ.OBJECT_NAME || ' compile body'; 
          else 
            EXECUTE IMMEDIATE 'alter ' || REC_OBJ.OBJECT_TYPE || ' ' || REC_OBJ.OWNER || '.' || REC_OBJ.OBJECT_NAME || ' compile'; 
          end if;
          dbms_output.put_line('OK '||REC_OBJ.OBJECT_TYPE||' '||REC_OBJ.OWNER||'.'||REC_OBJ.OBJECT_NAME||' is now valid.');
        EXCEPTION WHEN OTHERS THEN
          v_error := null;
          FOR REC_ERR IN C_OBJ_ERROR(REC_OBJ.OWNER, REC_OBJ.OBJECT_NAME) LOOP
            v_error := v_error||'['||REC_ERR.LINE||'] '||REC_ERR.TEXT;
          END LOOP;

          dbms_output.put_line('ERROR '||REC_OBJ.OBJECT_TYPE||' '||REC_OBJ.OWNER||'.'||REC_OBJ.OBJECT_NAME||' is in error '||v_error);
        END;
    END LOOP;
END;
/

PROMPT Compile objects in debug
DECLARE 
    CURSOR C_OBJ_DEBUG IS
        SELECT *
        FROM   SYS.ALL_PROBE_OBJECTS
        WHERE DEBUGINFO = 'T';
BEGIN
    FOR REC_OBJ IN C_OBJ_DEBUG LOOP
      if REC_OBJ.OBJECT_TYPE = 'PACKAGE BODY' then 
        EXECUTE IMMEDIATE 'alter ' || REC_OBJ.OBJECT_TYPE || ' ' || REC_OBJ.OWNER || '.' || REC_OBJ.OBJECT_NAME || ' compile body'; 
      else 
        EXECUTE IMMEDIATE 'alter ' || REC_OBJ.OBJECT_TYPE || ' ' || REC_OBJ.OWNER || '.' || REC_OBJ.OBJECT_NAME || ' compile'; 
      end if; 
    END LOOP;
END;
/

exit;