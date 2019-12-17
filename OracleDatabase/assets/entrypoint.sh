#!/bin/bash

reuse_database(){
	echo "Reuse existing database."
	if grep -q "$ORACLE_SID:" /etc/oratab ; then
		# starting an existing container
		echo "Database already registred in /etc/oratab"
	else
		# new container with an existing volume
		echo "Registering Database in /etc/oratab"
		echo "$ORACLE_SID:$ORACLE_HOME:N" >> /etc/oratab
		echo "Restore EM DB Console configuration"
		restore_from_volume
		set_timezone
	fi
	chown oracle:dba /etc/oratab
	chmod 664 /etc/oratab
	provide_data_as_single_volume
	su oracle bash -c "${ORACLE_HOME}/bin/lsnrctl start"
	su oracle bash -c 'echo startup\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
}

link_dir_to_volume(){
	LINK=${1}
	TARGET=${2}
	if  [ -d ${LINK} -a ! -d ${TARGET} ]; then
		echo "Moving original content of ${LINK} to ${TARGET}."
		mkdir -p ${TARGET}
		mv ${LINK}/* ${TARGET} || true
	fi
	rm -rf ${LINK}
	mkdir -p ${TARGET}
	chown -R oracle:dba ${TARGET} 
	echo "Link ${LINK} to ${TARGET}."
	ln -s ${TARGET} ${LINK}
	chown -R oracle:dba ${LINK}
}

copy_dir(){
	SOURCE=${1}
	TARGET=${2}
	echo "Copy ${SOURCE}/* to ${TARGET}."
	rm -rf ${TARGET}
	mkdir -p ${TARGET}
	cp -R ${SOURCE}/* ${TARGET} || true	
	chown -R oracle:dba ${TARGET}
}

save_to_volume(){
	# symbolic links are not working
	copy_dir "/u01/app/oracle/product/11.2.0/dbhome/oc4j/j2ee" "/u02/app/oracle/product/11.2.0/dbhome/oc4j/j2ee"
	copy_dir "/u01/app/oracle/product/11.2.0/dbhome/sysman" "/u02/app/oracle/product/11.2.0/dbhome/sysman"
	copy_dir "/u01/app/oracle/product/11.2.0/dbhome/${HOSTNAME}_${ORACLE_SID}" "/u02/app/oracle/product/11.2.0/dbhome/${HOSTNAME}_${ORACLE_SID}"
}

restore_from_volume(){
	copy_dir "/u02/app/oracle/product/11.2.0/dbhome/oc4j/j2ee" "/u01/app/oracle/product/11.2.0/dbhome/oc4j/j2ee"
	copy_dir "/u02/app/oracle/product/11.2.0/dbhome/sysman" "/u01/app/oracle/product/11.2.0/dbhome/sysman"
	copy_dir "/u02/app/oracle/product/11.2.0/dbhome/${HOSTNAME}_${ORACLE_SID}" "/u01/app/oracle/product/11.2.0/dbhome/${HOSTNAME}_${ORACLE_SID}"
}

provide_data_as_single_volume(){
	echo "Providing persistent data under /u02 to be used as Docker volume."
	link_dir_to_volume "/u01/app/oracle/product/11.2.0/dbhome/dbs" "/u02/app/oracle/product/11.2.0/dbhome/dbs" 
	link_dir_to_volume "/u01/app/oracle/admin" "/u02/app/oracle/admin"
	link_dir_to_volume "/u01/app/oracle/audit" "/u02/app/oracle/audit"
	link_dir_to_volume "/u01/app/oracle/cfgtoollogs" "/u02/app/oracle/cfgtoollogs"
	link_dir_to_volume "/u01/app/oracle/checkpoints" "/u02/app/oracle/checkpoints"
	link_dir_to_volume "/u01/app/oracle/diag" "/u02/app/oracle/diag"
	link_dir_to_volume "/u01/app/oracle/fast_recovery_area" "/u02/app/oracle/fast_recovery_area"
	link_dir_to_volume "/u01/app/oracle/oradata" "/u02/app/oracle/oradata"
	link_dir_to_volume "/u01/app/oracle/ords" "/u02/app/oracle/ords"
	chown -R oracle:dba /u02
}

set_timezone(){
	echo "Change timezone to Central European Time (CET)."
	unlink /etc/localtime
	ln -s /usr/share/zoneinfo/Europe/Brussels /etc/localtime
}

remove_domain_from_resolve_conf(){
	# Workaround to improve startup time of DBCA
	# remove domain entry, see MOS Doc ID 362092.1
	cp /etc/resolv.conf /etc/resolv.conf.ori
	sed 's/domain.*//' /etc/resolv.conf.ori > /etc/resolv.conf
}

create_database(){
	echo "Creating database."
	provide_data_as_single_volume
	remove_domain_from_resolve_conf
	su oracle bash -c "${ORACLE_HOME}/bin/lsnrctl start"
	if [ $DBCONTROL == "true" ]; then
		EM_CONFIGURATION=LOCAL
	else
		EM_CONFIGURATION=NONE
	fi
	su oracle bash -c "${ORACLE_HOME}/bin/dbca \
		-silent \
		-createDatabase \
		-templateName General_Purpose.dbc \
		-gdbname ${SERVICE_NAME} \
		-sid ${ORACLE_SID} \
		-responseFile NO_VALUE \
		-characterSet AL32UTF8 \
		-totalMemory $DBCA_TOTAL_MEMORY \
		-emConfiguration ${EM_CONFIGURATION} \
		-dbsnmpPassword ${PASS} \
		-sysmanPassword ${PASS} \
		-sysPassword ${PASS} \
		-systemPassword ${PASS} \
		-initparams java_jit_enabled=FALSE,audit_trail=NONE,audit_sys_operations=FALSE"


	#lsnrctl start &&
	#dbca -silent -createDatabase -responseFile $ORACLE_BASE/dbca.rsp -emConfiguration LOCAL ||
	# cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log ||
	# cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID.log

	echo "Configure listener."
	su oracle bash -c 'echo -e "ALTER SYSTEM SET LOCAL_LISTENER='"'"'(ADDRESS = (PROTOCOL = TCP)(HOST = $(hostname))(PORT = 1521))'"'"' SCOPE=BOTH;\n ALTER SYSTEM REGISTER;\n EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'

	#echo "Remove second control file"
	#su oracle bash -c 'echo -e "ALTER SYSTEM SET control_files='"'"'$ORACLE_BASE/oradata/${ORACLE_SID}/control01.ctl'"'"' scope=spfile;\n EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'	

	echo "Applying data patches."
	su oracle bash -c 'echo -e "@?/rdbms/admin/catbundle.sql PSU APPLY\n EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
	echo "Setting TWO_TASK environment for default connection."
	export CONNECT_STRING=${ORACLE_SID}
	echo "export CONNECT_STRING=${CONNECT_STRING}" >> /.oracle_env
	echo "export CONNECT_STRING=${CONNECT_STRING}" >> /home/oracle/.bash_profile
	echo "export CONNECT_STRING=${CONNECT_STRING}" >> /root/.bashrc
	echo "Save configuration to volume"
	save_to_volume
}

start_database(){
	# Startup database if oradata directory is found otherwise create a database
	if [ -d /u02/app/oracle/oradata ]; then
		reuse_database
	else
		set_timezone
		create_database
	fi

	# (re)start EM Database Console
	if [ $DBCONTROL == "true" ]; then
		su oracle bash -c "emctl stop dbconsole" || true
		su oracle bash -c "kill `ps -ef | grep emagent | awk '{print $2}'`" || true
		su oracle bash -c "emctl start dbconsole"
	fi

	# Successful installation/startup
	echo ""
	echo "Database ready to use. Enjoy! ;-)"

	# trap interrupt/terminate signal for graceful termination
	trap "su oracle bash -c 'echo Starting graceful shutdown... && echo shutdown immediate\; | ${ORACLE_HOME}/bin/sqlplus -S / as sysdba && /assets/stop_ords.sh && ${ORACLE_HOME}/bin/lsnrctl stop'" INT TERM

	# waiting for termination of tns listener
	PID=`ps -e | grep tnslsnr | awk '{print $1}'`
	while test -d /proc/$PID; do sleep 1; done
	echo "Graceful shutdown completed."
}

# set environment
. /assets/setenv.sh

# Exit script on non-zero command exit status
set -e

case "$1" in
	'')
		# default behaviour when no parameters are passed to the container
		start_database
		;;
	*)
		# use parameters passed to the container
		echo ""
		echo "Overridden default behaviour. Run /assets/entrypoint.sh when ready."
		$@
		;;
esac
