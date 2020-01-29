#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com, eric.clement@juxta.fr (11.2.0.4 version)
# Description: Creates an Oracle Database based on following parameters:
#              $ORACLE_SID: The Oracle SID name
#              $ORACLE_PWD: The Oracle password
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
echo -e "\033[32mstarting bash script $0\033[0m"
set -e

# Check whether ORACLE_SID is passed on
export ORACLE_SID=${1:-ORCL}
echo "ORACLE_SID=$ORACLE_SID"

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${2:-"`openssl rand -base64 8`1"}
echo -e "ORACLE PASSWORD FOR SYS, SYSTEM : \033[0;31m$ORACLE_PWD\033[0m";

# If there is greater than 8 CPUs default back to dbca memory calculations
# dbca will automatically pick 40% of available memory for Oracle DB
# The minimum of 2G is for small environments to guarantee that Oracle has enough memory to function
# However, bigger environment can and should use more of the available memory
# This is due to Github Issue #307
export DBCA_TOTAL_MEMORY=${3:-"-totalMemory 2048"}
if [ `nproc` -gt 8 ]; then
   DBCA_TOTAL_MEMORY="-totalMemory 2048"
fi;


# Create network related config files (sqlnet.ora, tnsnames.ora, listener.ora)
mkdir -p $ORACLE_HOME/network/admin
echo "NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)" > $ORACLE_HOME/network/admin/sqlnet.ora

# Listener.ora
echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
" > $ORACLE_HOME/network/admin/listener.ora

echo "DBCONTROL=$DBCONTROL"
if [ $DBCONTROL == "true" ]; then
  EM_CONFIGURATION=LOCAL
else
  EM_CONFIGURATION=NONE
fi

# Start LISTENER and run DBCA
lsnrctl start &&
dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname ${ORACLE_SID} -sid ${ORACLE_SID} -responseFile NO_VALUE -characterSet $ORACLE_CHARACTERSET $DBCA_TOTAL_MEMORY -emConfiguration ${EM_CONFIGURATION} -dbsnmpPassword ${ORACLE_PWD} -sysmanPassword ${ORACLE_PWD} -sysPassword ${ORACLE_PWD} -systemPassword ${ORACLE_PWD} -initparams java_jit_enabled=FALSE,audit_trail=NONE,audit_sys_operations=FALSE,nls_language="FRENCH",nls_territory="FRANCE",processes=300,sessions=335 -sampleSchema false||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log ||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID.log

####
echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" > $ORACLE_HOME/network/admin/tnsnames.ora
echo "$ORACLE_SID= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_SID)
  )
)" >> $ORACLE_HOME/network/admin/tnsnames.ora

#echo -e "ALTER SYSTEM SET LOCAL_LISTENER='(ADDRESS = (PROTOCOL = TCP)(HOST = $(hostname))(PORT = 1521))' SCOPE=BOTH;\n ALTER SYSTEM REGISTER;\n EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba

# Remove second control file, fix local_listener, enable EM global port
sqlplus / as sysdba << EOF
   ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
   --EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
   exit;
EOF

