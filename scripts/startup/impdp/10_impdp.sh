#!/usr/bin/env bash
set -e

export ORACLE_SID=${ORACLE_SID}
LOCAL_SCRIPT_ROOT="/opt/oracle/scripts/startup"

alert_log="$ORACLE_BASE/diag/rdbms/orcl/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
pfile=$ORACLE_HOME/dbs/init$ORACLE_SID.ora

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | sed --unbuffered -e 's/\(.*erreur.*\)/\o033[31m\1\o033[39m/' | while read line; do echo -e "\033[0;35m$2\033[0m $3: $line"; done
}

trap_db() {
	trap "echo 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
	trap "echo 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
}

change_dpdump_dir () {
	echo "Changing dpdump dir to ${LOCAL_SCRIPT_ROOT}"
	sqlplus -s / as sysdba <<-EOF |
		create or replace directory data_pump_dir as '${LOCAL_SCRIPT_ROOT}';

		set linesize 90
		col owner format a10
		col directory_name format a20
		col directory_path format a50
		select * from all_directories where directory_name = 'DATA_PUMP_DIR';

		exit 0
	EOF
	while read line; do echo -e "\033[0;35msqlplus\033[0m: $line"; done
}

download() {
	echo "Download dumpfile ${ASSETS_LOCATION}/ to ${LOCAL_SCRIPT_ROOT}/"
	wget -q --no-check-certificate ${ASSETS_LOCATION}/ -O ${LOCAL_SCRIPT_ROOT}/${DUMPFILE}
}

# import dump $DUMPFILE
import() {
    DUMPFILE=$1
	if [ -f ${DUMPFILE} ]; then

		echo "#########################################################################################"
		echo "Import dump `basename ${DUMPFILE}`..."
		echo "#########################################################################################"
		echo " "	
		
		impdp \"/ as sysdba\" directory=data_pump_dir dumpfile=`basename ${DUMPFILE}` logfile=`basename ${DUMPFILE}`.$$.log table_exists_action=replace >&2 > /dev/null | sed --unbuffered -e 's/\(.*ORA-.*\)/\o033[31m\1\o033[39m/'
	
		IMPDP_EXIT_CODE=${?}
		wait `pidof impdp`
		rm -f ${DUMPFILE}

		if [ $IMPDP_EXIT_CODE -eq 0 ]
		then
			echo -e "Dumpfile \033[32m`basename ${DUMPFILE}` imported.\033[0m"
		elif [ $IMPDP_EXIT_CODE -eq 1 ] || [ $IMPDP_EXIT_CODE -eq 2 ] || [ $IMPDP_EXIT_CODE -eq 3 ]
		then
			echo -e "IMPDP \033[0;31m${DUMPFILE} FAILED !\033[0m"
		fi
	else
		echo -e "Dumpfile \033[0;31m${DUMPFILE} does not exists !\033[0m"
	fi
}

#main
#Note : you can call "download" if dumpfile is located elsewere...
#download
change_dpdump_dir
cd ${LOCAL_SCRIPT_ROOT}
# Execute custom provided files (only if directory exists and has files in it)
if [ -d "$LOCAL_SCRIPT_ROOT" ] && [ -n "$(ls -A $LOCAL_SCRIPT_ROOT)" ]; then

  echo "Checking for zipped files"
  for f in $LOCAL_SCRIPT_ROOT/*; do
      shopt -s nocasematch
      case "$f" in
          *.zip)    echo "$0: unzip $f"; unzip -Coj $f; echo ;;
		  *.7z)     echo "$0: unzip $f"; 7za e $f; echo ;;
      esac
      echo "";
  done

  echo "Checking for dump files"
  for f in $LOCAL_SCRIPT_ROOT/*; do
      shopt -s nocasematch
      case "$f" in
          *.dmp)    echo -e "$0: \033[32mimporting\033[0m $f"; import "$f"; echo ;;
      esac
      echo "";
  done

fi;

echo -e "\033[32mDONE\033[0m: $0"
echo "";

