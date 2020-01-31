set feedback off verify off heading off pagesize 0 newpage 0;
select name, created from v$database;

--Locked account
SELECT username||' '|| lock_date ||' '|| account_status
FROM dba_users
where ACCOUNT_STATUS like 'EXPIRED(GRACE)' or ACCOUNT_STATUS like 'LOCKED(TIMED)'
UNION
SELECT username||' '|| lock_date ||' '|| account_status
FROM dba_users
WHERE account_status <> 'OPEN'
AND (lock_date >= sysdate-7 OR (expiry_date <= sysdate-15 AND expiry_date > sysdate-15));

exit;


