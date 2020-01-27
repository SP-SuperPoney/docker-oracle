#!/usr/bin/env bash
echo -e "\033[32mstarting bash script $0\033[0m"
set -e

export ORACLE_SID=${ORACLE_SID}
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
	trap "echo 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
	trap "echo 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
}

change_dpdump_dir () {
	echo "Changing dpdump dir to ${ORACLE_BASE}/admin/${ORACLE_SID}/dpdump"
	sqlplus / as sysdba <<-EOF |
		create or replace directory data_pump_dir as '${ORACLE_BASE}/admin/${ORACLE_SID}/dpdump';

		set linesize 90
		col owner format a10
		col directory_name format a20
		col directory_path format a50
		select * from all_directories where directory_name = 'DATA_PUMP_DIR';

		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}

# import dump $DUMPFILE
import() {
	echo "Download dumpfile ${ASSETS_LOCATION}/${DUMPFILE} to ${ORACLE_BASE}/admin/${ORACLE_SID}/dpdump"
	wget -q --no-check-certificate ${ASSETS_LOCATION}/${DUMPFILE} -O ${ORACLE_BASE}/admin/${ORACLE_SID}/dpdump/${DUMPFILE}

	if [ -f ${ORACLE_BASE}/admin/${ORACLE_SID}/dpdump/${DUMPFILE} ]; then
		change_dpdump_dir
		echo "Import dump ${ASSETS_LOCATION}/${DUMPFILE}..."
		impdp \"/ as sysdba\" directory=data_pump_dir dumpfile=${DUMPFILE} logfile=$DUMPFILE.$$.log table_exists_action=replace
		monitor ${ORACLE_BASE}/admin/${ORACLE_SID}/dpdump/$DUMPFILE.$$.log log_import &	
		MON_IMPDP_PID=$!
		rm -f ${ASSETS_LOCATION}/${DUMPFILE}
		echo "Dump $DUMPFILE imported."
	else
		echo "Dumpfile ${ASSETS_LOCATION}/${DUMPFILE} does not exists !"
	fi
}

if [ -n "$DUMPFILE" ]; then
	import
else
	echo "Dumpfile not specified import skipped."
fi

