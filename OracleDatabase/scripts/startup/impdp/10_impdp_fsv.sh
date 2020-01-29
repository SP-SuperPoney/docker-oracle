#!/usr/bin/env bash
echo -e "\033[32mstarting bash script $0\033[0m"
set -e

export ORACLE_SID=${ORACLE_SID}
alert_log="$ORACLE_BASE/diag/rdbms/orcl/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
pfile=$ORACLE_HOME/dbs/init$ORACLE_SID.ora

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}

trap_db() {
	trap "echo 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
	trap "echo 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
}

change_dpdump_dir () {
	echo "Changing dpdump dir to ${DUMPPATH}"
	sqlplus / as sysdba <<-EOF |
		create or replace directory data_pump_dir as '${DUMPPATH}';

		set linesize 90
		col owner format a10
		col directory_name format a20
		col directory_path format a50
		select * from all_directories where directory_name = 'DATA_PUMP_DIR';

		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}

download() {
	echo "Download dumpfile ${ASSETS_LOCATION}/${DUMPFILE} to ${DUMPPATH}/"
	wget -q --no-check-certificate ${ASSETS_LOCATION}/${DUMPFILE} -O ${DUMPPATH}/${DUMPFILE}
}

# import dump $DUMPFILE
import() {
	if [ -f ${DUMPPATH}/${DUMPFILE} ]; then
		change_dpdump_dir
		echo "Import dump ${DUMPPATH}/${DUMPFILE}..."
		impdp \"/ as sysdba\" directory=data_pump_dir dumpfile=${DUMPFILE} NOLOGFILE=YES
		#rm -f ${DUMPFILE}/${DUMPFILE}
		echo -e "Dump file \033[32m${DUMPFILE} imported.\033[0m"
	else
		echo -e "Dumpfile \033[0;31m${DUMPPATH}/${DUMPFILE} does not exists !\033[0m"
	fi
}

#main
DUMPPATH="/opt/oracle/scripts/startup"
DUMPFILE="FSV_MINI_1.02.DMP"

if [ -n "$DUMPFILE" ]; then
	#Sample: you can call "download" if dumpfile is located elsewere...
	#download
	import
else
	echo -e "\033[0;33mDumpfile not specified import skipped.\033[0m"
fi

