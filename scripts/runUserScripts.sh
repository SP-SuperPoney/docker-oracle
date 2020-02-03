#!/bin/bash
SCRIPTS_ROOT="$1";
echo -e "\033[32mstarting bash script $0\033[0m"


# Check whether parameter has been passed on
if [ -z "$SCRIPTS_ROOT" ]; then
   echo "$0: No SCRIPTS_ROOT passed on, no scripts will be run";
   exit 1;
else
  echo "SCRIPTS_ROOT=$SCRIPTS_ROOT"
fi;

# Execute custom provided files (only if directory exists and has files in it)
if [ -d "$SCRIPTS_ROOT" ] && [ -n "$(ls -A $SCRIPTS_ROOT)" ]; then

  echo "";
  echo "Executing user defined scripts"

  for f in $SCRIPTS_ROOT/*; do
      case "$f" in
          *.sh)     echo -e "$0: \033[32mrunning\033[0m $f"; . "$f" ;;
          *.sql)    echo -e "$0: \033[32mrunning\033[0m $f"; echo "exit" | $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" @"$f"; echo ;;
          *)        echo -e "$0: \033[0;33mignoring\033[0m $f" ;;
      esac
      echo "";
  done
  
  echo -e "\033[32mDONE\033[0m: Executing user defined scripts"
  echo "";

fi;