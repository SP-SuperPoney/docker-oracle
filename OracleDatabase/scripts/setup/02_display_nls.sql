set head on
set pagesize 100
set line 150
col PARAMETER for a25;
col Base for a30;
col Instance for a12;
col Session for a30;

select
d.parameter, d.value "Base", i.value "Instance", s.value "Session"
from
nls_database_parameters d, nls_instance_parameters i, nls_session_parameters s
where
d.parameter=i.parameter(+)
and
d.parameter=s.parameter(+)
;

exit;
