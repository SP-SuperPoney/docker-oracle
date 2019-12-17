#!/bin/bash

apex_epg_config(){
	if [ $ORDS == "false" ]; then
		cd ${ORACLE_HOME}/apex
		echo "Setting up EPG for APEX by running: @apex_epg_config ${ORACLE_HOME}"
		echo "EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS SYSDBA @apex_epg_config ${ORACLE_HOME}
		echo "Unlock anonymous account"
		echo "ALTER USER ANONYMOUS ACCOUNT UNLOCK;" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS SYSDBA
		echo "Optimizing EPG performance"
		echo "ALTER SYSTEM SET SHARED_SERVERS=15 SCOPE=BOTH;" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS SYSDBA
		echo -e "ALTER SYSTEM SET DISPATCHERS='(PROTOCOL=TCP) (SERVICE=${ORACLE_SID}XDB) (DISPATCHERS=3)' SCOPE=BOTH;" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS SYSDBA
	fi
}

apex_create_tablespace(){
	echo "Creating APEX tablespace."
	DATAFILE=${ORACLE_BASE}/oradata/${ORACLE_SID}/apex01.dbf
	${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS SYSDBA <<EOF
		CREATE TABLESPACE apex DATAFILE '${DATAFILE}' SIZE 100M AUTOEXTEND ON NEXT 10M;
EOF
}

apex_install(){
	cd $ORACLE_HOME/apex
	echo "Installing APEX."
	echo "EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS SYSDBA @apexins APEX APEX TEMP /i/
	echo "Setting APEX ADMIN password."
 	echo -e "\n\n${APEX_PASS}" | sql -s -l sys/${PASS}@${CONNECT_STRING} AS sysdba @apxchpwd.sql
}

apex_rest_config() {
	if [ $ORDS == "true" ]; then
		cd $ORACLE_HOME/apex
		echo "Getting ready for ORDS. Creating user APEX_LISTENER and APEX_REST_PUBLIC_USER."
		echo -e "${PASS}\n${PASS}" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS sysdba @apex_rest_config.sql
		echo "ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS SYSDBA
		echo "ALTER USER APEX_PUBLIC_USER IDENTIFIED BY ${PASS};" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${CONNECT_STRING} AS SYSDBA
	fi
}

apex_create_tablespace
apex_install
apex_epg_config
apex_rest_config
cd /
