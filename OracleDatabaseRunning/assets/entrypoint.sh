#!/bin/bash
export ORACLE_SID=${ORACLE_SID^^}
export ORACLE_VOLUME_BASE=/u02/app/oracle

source /assets/colorecho

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
		#restore_from_volume
		set_timezone
	fi
	chown oracle:dba /etc/oratab
	chmod 664 /etc/oratab
	#provide_data_as_single_volume
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
	copy_dir "${ORACLE_BASE}/product/11.2.0/dbhome/oc4j/j2ee" "${ORACLE_VOLUME_BASE}/product/11.2.0/dbhome/oc4j/j2ee"
	copy_dir "${ORACLE_BASE}/product/11.2.0/dbhome/sysman" "${ORACLE_VOLUME_BASE}/product/11.2.0/dbhome/sysman"
	copy_dir "${ORACLE_BASE}/product/11.2.0/dbhome/${HOSTNAME}_${ORACLE_SID}" "${ORACLE_VOLUME_BASE}/product/11.2.0/dbhome/${HOSTNAME}_${ORACLE_SID}"
}

restore_from_volume(){
	copy_dir "${ORACLE_VOLUME_BASE}/product/11.2.0/dbhome/oc4j/j2ee" "${ORACLE_BASE}/product/11.2.0/dbhome/oc4j/j2ee"
	copy_dir "${ORACLE_VOLUME_BASE}/product/11.2.0/dbhome/sysman" "${ORACLE_BASE}/product/11.2.0/dbhome/sysman"
	copy_dir "${ORACLE_VOLUME_BASE}/product/11.2.0/dbhome/${HOSTNAME}_${ORACLE_SID}" "${ORACLE_BASE}/product/11.2.0/dbhome/${HOSTNAME}_${ORACLE_SID}"
}

provide_data_as_single_volume(){
	echo "Providing persistent data under ${ORACLE_VOLUME_BASE} to be used as Docker volume."
	link_dir_to_volume "${ORACLE_BASE}/product/11.2.0/dbhome/dbs" "${ORACLE_VOLUME_BASE}/product/11.2.0/dbhome/dbs" 
	link_dir_to_volume "${ORACLE_BASE}/admin" "${ORACLE_VOLUME_BASE}/admin"
	link_dir_to_volume "${ORACLE_BASE}/audit" "${ORACLE_VOLUME_BASE}/audit"
	link_dir_to_volume "${ORACLE_BASE}/cfgtoollogs" "${ORACLE_VOLUME_BASE}/cfgtoollogs"
	link_dir_to_volume "${ORACLE_BASE}/checkpoints" "${ORACLE_VOLUME_BASE}/checkpoints"
	link_dir_to_volume "${ORACLE_BASE}/diag" "${ORACLE_VOLUME_BASE}/diag"
	link_dir_to_volume "${ORACLE_BASE}/fast_recovery_area" "${ORACLE_VOLUME_BASE}/fast_recovery_area"
	link_dir_to_volume "${ORACLE_BASE}/oradata" "${ORACLE_VOLUME_BASE}/oradata"
	link_dir_to_volume "${ORACLE_BASE}/ords" "${ORACLE_VOLUME_BASE}/ords"
	chown -R oracle:dba ${ORACLE_VOLUME_BASE}
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

prerequisites(){
	echo "Check whether container has enough memory"
	# Github issue #219: Prevent integer overflow,
	# only check if memory digits are less than 11 (single GB range and below) 
	if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes | wc -c` -lt 11 ]; then
		if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes` -lt 1073741824 ]; then
			echo "Error: The container doesn't have enough memory allocated."
			echo "A database container needs at least 1 GB of memory."
			echo "You currently only have $((`cat /sys/fs/cgroup/memory/memory.limit_in_bytes`/1024/1024/1024)) GB allocated to the container."
			exit 1;
		fi;
	fi;

	echo "Check that hostname doesn't container any _"
	# Github issue #711
	if hostname | grep -q "_"; then
		echo "Error: The hostname must not container any '_'".
		echo "Your current hostname is '$(hostname)'"
	fi;

	echo "Check ORACLE SID"
	# Default for ORACLE SID
	if [ "$ORACLE_SID" == "" ]; then
		export ORACLE_SID=ORCL
	else
		# Make ORACLE_SID upper case
		# Github issue # 984
		export ORACLE_SID=${ORACLE_SID^^}

		# Check whether SID is no longer than 12 bytes
		# Github issue #246: Cannot start OracleDB image
		if [ "${#ORACLE_SID}" -gt 12 ]; then
			echo "Error: The ORACLE_SID must only be up to 12 characters long."
			exit 1;
		fi;

		# Check whether SID is alphanumeric
		# Github issue #246: Cannot start OracleDB image
		if [[ "$ORACLE_SID" =~ [^a-zA-Z0-9] ]]; then
			echo "Error: The ORACLE_SID must be alphanumeric."
			exit 1;
		fi;
	fi;	
}

create_database(){
	prerequisites
	echo "Creating database."
	#provide_data_as_single_volume
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
	#save_to_volume
}

post_create_db(){
	chown -R oracle:oinstall ${ORACLE_BASE}/admin/oracle/dpdump
	su oracle -c "/assets/entrypoint_oracle.sh"
}

start_database(){
	# Startup database if oradata directory is found otherwise create a database
	if [ -d ${ORACLE_BASE}/oradata ]; then
		reuse_database
	else
		set_timezone
		create_database
		post_create_db
	fi

	# (re)start EM Database Console
	if [ $DBCONTROL == "true" ]; then
		su oracle bash -c "emctl stop dbconsole" || true
		su oracle bash -c "kill `ps -ef | grep emagent | awk '{print $2}'`" || true
		su oracle bash -c "emctl start dbconsole"
	fi

	# Successful installation/startup
	echo ""
	echo_green "Database ready to use. Enjoy! ;-)"

	# Tail on alert log
	echo "The following output is now a tail of the alert.log:"
	tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert*.log &

	# trap interrupt/terminate signal for graceful termination
	trap "su oracle bash -c 'echo Starting graceful shutdown... && echo shutdown immediate\; | ${ORACLE_HOME}/bin/sqlplus -S / as sysdba && ${ORACLE_HOME}/bin/lsnrctl stop'" INT TERM

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
