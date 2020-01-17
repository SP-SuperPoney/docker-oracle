#!/usr/bin/env bash

set -e
source /assets/colorecho
source ~/.bashrc

echo_green "starting bash script $0"
export ORACLE_SID=${ORACLE_SID^^}
alert_log="$ORACLE_BASE/diag/rdbms/orcl/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
pfile=$ORACLE_HOME/dbs/init$ORACLE_SID.ora
pre_impdp_script=/assets/sql/pre_impdp.sql
post_impdp_script=/assets/sql/post_impdp.sql

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}


trap_db() {
	trap "echo_red 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
	trap "echo_red 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
}

change_dpdump_dir () {
	echo_green "Changing dpdump dir to ${ORACLE_BASE}/admin/${ORACLE_SID^^}/dpdump"
	sqlplus / as sysdba <<-EOF |
		create or replace directory data_pump_dir as '${ORACLE_BASE}/admin/${ORACLE_SID^^}/dpdump';

		set linesize 90
		col owner format a10
		col directory_name format a20
		col directory_path format a50
		select * from all_directories where directory_name = 'DATA_PUMP_DIR';

		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}

pre_impdp() {
	echo_green "Executing pre dump import script..."
	date "+%F %T"
	sqlplus / as sysdba @$pre_impdp_script $ORACLE_BASE ${ORACLE_SID^^}
	#while read line; do echo -e "sqlplus_pre_impdp: $line"; done
}

post_impdp() {
	echo_green "Executing post dump import script..."
	date "+%F %T"
	sqlplus / as sysdba @$post_impdp_script
	#while read line; do echo -e "sqlplus_post_impdp: $line"; done
}

# import dump $DUMPFILE
import() {
	echo_green "Download dumpfile ${ORACLE_ASSETS}/${DUMPFILE} to ${ORACLE_BASE}/admin/${ORACLE_SID^^}/dpdump/${DUMPFILE}"
	wget -q --no-check-certificate ${ORACLE_ASSETS}/${DUMPFILE} -O ${ORACLE_BASE}/admin/${ORACLE_SID^^}/dpdump/${DUMPFILE}

	if [ -f ${ORACLE_BASE}/admin/${ORACLE_SID^^}/dpdump/${DUMPFILE} ]; then
		change_dpdump_dir
		echo "Import dump ${ORACLE_ASSETS}/${DUMPFILE}..."
		impdp \"/ as sysdba\" directory=data_pump_dir dumpfile=${DUMPFILE} logfile=$DUMPFILE.$$.log table_exists_action=replace
		monitor ${ORACLE_BASE}/admin/${ORACLE_SID^^}/dpdump/$DUMPFILE.$$.log log_import &	
		MON_IMPDP_PID=$!
		rm -f ${ORACLE_ASSETS}/${DUMPFILE}
		echo_green "Dump $DUMPFILE imported."
	else
		echo_yellow "Dumpfile ${ORACLE_ASSETS}/${DUMPFILE} does not exists !"
	fi
}

if [ -n "$DUMPFILE" ]; then
	pre_impdp
	import
	post_impdp
else
	echo_yellow "Dumpfile not specified import skipped, database is ready."
fi

