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



# Execute custom provided files (only if directory exists and has files in it)
if [ -d "$LOCAL_SCRIPT_ROOT" ] && [ -n "$(ls -A $LOCAL_SCRIPT_ROOT)" ]; then

  echo_green "Checking for zipped files"
  for f in $LOCAL_SCRIPT_ROOT/*; do
      shopt -s nocasematch
      case "$f" in
          *.zip)    echo "$0: unzip $f"; unzip -Coj $f "*.sql"; rm -rf $f; echo ;;
      esac
      echo "";
  done

  echo_green "";
  echo_green "Executing user defined scripts"
  for f in $LOCAL_SCRIPT_ROOT/*; do
      case "$f" in
          *.sh)     echo "$0: running $f"; . "$f" ;;
          *.sql)    echo "$0: running $f"; sqlplus_on_behalf "${f}";echo ;;
          *)        echo "$0: ignoring $f" ;;
      esac
      echo "";
  done
  
  echo "DONE: Executing user defined scripts"
  echo "";

fi;


# Execute custom provided files (only if directory exists and has files in it)
if [ -d "$DUMPPATH" ] && [ -n "$(ls -A $DUMPPATH)" ]; then

  for f in $DUMPPATH/*.; do
      case "$f" in
          *.dmp)     echo -e "$0: \033[32mrunning\033[0m $f"; . "$f" ;;
          *.DMP)    echo -e "$0: \033[32mrunning\033[0m $f"; echo "exit" | $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" @"$f"; echo ;;
          *)        echo -e "$0: \033[0;33mignoring\033[0m $f" ;;
      esac
      echo "";
  done
  
  echo -e "\033[32mDONE\033[0m: Executing user defined scripts"
  echo "";

fi;
