#!/usr/bin/env bash


set -e
source /assets/colorecho
source ~/.bashrc

echo_green "starting bash script $0"
echo ""
echo Parameters:
echo ORACLE_ASSETS=$ORACLE_ASSETS
echo RUN_SCRIPTS_IN_SCHEMA=$RUN_SCRIPTS_IN_SCHEMA
echo SCRIPTS_ROOT=$SCRIPTS_ROOT

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}

sqlplus_on_behalf(){
    echo_green "Executing $1 on behalf of $RUN_SCRIPTS_IN_SCHEMA..."
    #echo "exit" | $ORACLE_HOME/bin/sqlplus -s "/ as sysdba"/[$RUN_SCRIPTS_IN_SCHEMA] @"$1" >> "${LOCAL_SCRIPT_ROOT}/log/$$.log"
    #echo "Start query on %%c/[%%s]******@\"%%b/%%a\" @%SQL_FILE2% %%a %%s "%SPOOL_PATH%" %%c"
    #monitor "${LOCAL_SCRIPT_ROOT}/log/$$.log"
    if [ -f ${LOCAL_SCRIPT_ROOT}/log/$$.log ]; then
        cat "${LOCAL_SCRIPT_ROOT}/log/$$.log"
    fi
}

# Check whether parameter has been passed on
if [ -z "$SCRIPTS_ROOT" ]; then
   echo "$0: No SCRIPTS_ROOT passed on, no scripts will be run";
   exit 1;
fi;

LOCAL_SCRIPT_ROOT=~/runUserScripts/$$
rm -rf ${LOCAL_SCRIPT_ROOT}
mkdir -p -m 755 ${LOCAL_SCRIPT_ROOT}
mkdir -p -m 755 ${LOCAL_SCRIPT_ROOT}/log

echo_green "Download file(s) from ${ORACLE_ASSETS}/${SCRIPTS_ROOT} to ${LOCAL_SCRIPT_ROOT}"
cd ${LOCAL_SCRIPT_ROOT}
wget --no-directories --accept=sql,sh,zip,7z,gzip -r --no-parent ${ORACLE_ASSETS}/${SCRIPTS_ROOT}/ 

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