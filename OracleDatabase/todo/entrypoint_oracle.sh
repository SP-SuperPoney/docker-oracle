#!/usr/bin/env bash

set -e
source /assets/colorecho
source ~/.bashrc

echo_green "starting bash script $0"
alert_log="$ORACLE_BASE/diag/rdbms/orcl/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
pfile=$ORACLE_HOME/dbs/init$ORACLE_SID.ora
post_create_db_script=/assets/sql/post_dbcreate.sql
post_impdp_script=/assets/sql/post_impdp.sql
dump_file_arg=$1

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}


trap_db() {
	trap "echo_red 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
	trap "echo_red 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
}

post_impdp() {
	echo_green "Executing post dump import script..."
	date "+%F %T"
	sqlplus / as sysdba @$post_impdp_script
	while read line; do echo -e "sqlplus_post_impdp: $line"; done
}

post_create_db() {
	echo_green "Executing post database creation script..."
	date "+%F %T"
	sqlplus / as sysdba @$post_create_db_script $ORACLE_BASE $ORACLE_SID
	while read line; do echo -e "sqlplus_post_create_db: $line"; done
}

# import dump $dump_file_arg
import() {
	change_dpdump_dir
	echo_yellow "Import dump $dump_file_arg..."
	impdp \"/ as sysdba\" directory=data_pump_dir dumpfile=$dump_file_arg logfile=$dump_file_arg.$$.log table_exists_action=replace
	monitor /opt/oracle/dpdump/$dump_file_arg.$$.log log_import &	
	MON_IMPDP_PID=$!
	echo_yellow "Dump $dump_file_arg imported."
	post_impdp
}

start_db() {
	echo_yellow "Starting listener..."
	monitor $listener_log listener &
	lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
	MON_LSNR_PID=$!
	echo_yellow "Starting database..."
	trap_db
	monitor $alert_log alertlog &
	MON_ALERT_PID=$!
	sqlplus / as sysdba <<-EOF |
		pro Starting with pfile='$pfile' ...
		startup;
		alter system register;
		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
	echo_yellow "Database is up"
}

create_db() {
	echo_yellow "Database does not exist. Creating database..."
	date "+%F %T"
	monitor $alert_log alertlog &
	MON_ALERT_PID=$!
	monitor $listener_log listener &
	#lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
	#MON_LSNR_PID=$!
	echo "START DBCA"
	dbca -silent -createDatabase -responseFile /assets/dbca.rsp
	echo_green "Database created."
	date "+%F %T"
	change_dpdump_dir
	touch $pfile
	trap_db
	kill $MON_ALERT_PID
	#wait $MON_ALERT_PID
}

stop() {
    trap '' SIGINT SIGTERM
	shu_immediate
	echo_yellow "Shutting down listener..."
	lsnrctl stop | while read line; do echo -e "lsnrctl: $line"; done
	kill $MON_ALERT_PID $MON_LSNR_PID
	exit 0
}

shu_immediate() {
	ps -ef | grep ora_pmon | grep -v grep > /dev/null && \
	echo_yellow "Shutting down the database..." && \
	sqlplus / as sysdba <<-EOF |
		set echo on
		shutdown immediate;
		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}

change_dpdump_dir () {
	echo_green "Changind dpdump dir to /opt/oracle/dpdump"
	sqlplus / as sysdba <<-EOF |
		create or replace directory data_pump_dir as '/opt/oracle/dpdump';
		commit;
		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}

echo "Checking shared memory..."
df -h | grep "Mounted on" && df -h | egrep --color "^.*/dev/shm" || echo "Shared memory is not mounted."
if [ ! -f $pfile ]; then
  create_db;
  post_create_db;
fi 

start_db

if [ -n "$dump_file_arg" ]; then
	import
else
	wait $MON_ALERT_PID
fi
echo_green "Start hacking, database is ready."

