#!/bin/bash

# ignore secure linux
#setenforce Permissive
set -e

source /assets/colorecho
trap "echo_red '******* ERROR: Something went wrong.'; exit 1" SIGTERM
trap "echo_red '******* Caught SIGINT signal. Stopping...'; exit 2" SIGINT

echo "Configuring users"
# create oracle groups
groupadd --gid 54321 oinstall
groupadd --gid 54322 dba
groupadd --gid 54323 oper

# create oracle user
useradd --create-home --gid oinstall --groups oinstall,dba --uid 54321 oracle

# echo "oracle:install" | chpasswd
# echo "root:install" | chpasswd
#sed -i "s/pam_namespace.so/pam_namespace.so\nsession    required     pam_limits.so/g" /etc/pam.d/login

#Install prerequisites directly without virtual package
echo "Installing dependencies"
#yum -y install binutils compat-libstdc++-33 compat-libstdc++-33.i686 ksh elfutils-libelf elfutils-libelf-devel glibc glibc-common glibc-devel gcc gcc-c++ libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make sysstat unixODBC unixODBC-devel
yum install -y oracle-rdbms-server-11gR2-preinstall \
            perl \
            tar \
            unzip \
            wget
yum clean all
rm -rf /var/lib/{cache,log} /var/log/lastlog

##################

#fix "su cannot open session bug"
cat /assets/su.patch > /etc/pam.d/su

##################
# download and extract JDK (required by sqlcl)
echo "downloading JDK..."
wget -q --no-check-certificate ${ORACLE_ASSETS}/jdk-8u231-linux-x64.rpm -O /tmp/jdk.rpm
echo "installing JDK..."
rpm -i /tmp/jdk.rpm
rm /tmp/jdk.rpm

# environment variables (not configurable when creating a container)
echo "export JAVA_HOME=\$(readlink -f /usr/bin/javac | sed \"s:/bin/javac::\")" > /.oracle_env 
echo "export ORACLE_BASE=/u01/app/oracle" >> /.oracle_env
echo "export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/dbhome" >> /.oracle_env
echo "export PATH=/usr/sbin:\$PATH:/opt/sqlcl/bin" >> /.oracle_env
echo "export PATH=\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch:\$PATH" >> /.oracle_env
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib" >> /.oracle_env
echo "export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib" >> /.oracle_env
echo "export TMP=/tmp" >> /.oracle_env
echo "export TMPDIR=\$TMP" >> /.oracle_env
echo "export TERM=linux" >> /.oracle_env # avoid in sqlcl: "tput: No value for $TERM and no -T specified"
chmod +x /.oracle_env

# set environment
. /.oracle_env
cat /.oracle_env >> /home/oracle/.bash_profile
cat /.oracle_env >> /root/.bashrc # .bash_profile not executed by docker

# create directories
mkdir -p /u01/app/oracle
mkdir -p /u01/app/oraInventory
mkdir -p /tmp/oracle
chown -R oracle:oinstall /u01
chown -R oracle:oinstall /tmp/oracle

# download and extract Oracle database software
echo "downloading Oracle database software..."
wget -q --no-check-certificate ${ORACLE_ASSETS}/p13390677_112040_Linux-x86-64_1of7.zip -O /tmp/oracle/db1.zip
wget -q --no-check-certificate ${ORACLE_ASSETS}/p13390677_112040_Linux-x86-64_2of7.zip -O /tmp/oracle/db2.zip
chown oracle:oinstall /tmp/oracle/db1.zip
chown oracle:oinstall /tmp/oracle/db2.zip
echo "extracting Oracle database software..."
su oracle bash -c "unzip -o /tmp/oracle/db1.zip -d /tmp/oracle/" > /dev/null
su oracle bash -c "unzip -o /tmp/oracle/db2.zip -d /tmp/oracle/" > /dev/null
rm -f /tmp/oracle/db1.zip
rm -f /tmp/oracle/db2.zip

# install Oracle software into ${ORACLE_BASE}
chown oracle:oinstall /assets/db_install.rsp
echo "running Oracle installer to install database software only..."
su oracle bash -c "/tmp/oracle/database/runInstaller -silent -force -waitforcompletion -responsefile /assets/db_install.rsp -ignoresysprereqs -ignoreprereq"

# run Oracle root scripts
echo "running Oracle root scripts..."
/u01/app/oraInventory/orainstRoot.sh > /dev/null 2>&1 || true
${ORACLE_HOME}/root.sh > /dev/null 2>&1 || true

# remove original OPatch folder to save disk space
rm -r -f ${ORACLE_HOME}/OPatch

# download and install patch 6880880
echo "downloading OPatch..."
wget -q --no-check-certificate ${ORACLE_ASSETS}/p6880880_112000_Linux-x86-64.zip -O /tmp/oracle/p6880880.zip
chown oracle:oinstall /tmp/oracle/p6880880.zip
echo "extracting and installing OPatch..."
su oracle bash -c "unzip -o /tmp/oracle/p6880880.zip -d ${ORACLE_HOME}/" > /dev/null
rm -f /tmp/oracle/p6880880.zip

# # download and install patch p28729262
# wget -q --no-check-certificate ${ORACLE_ASSETS}/p28729262_112040_Linux-x86-64.zip -O /tmp/oracle/patch.zip
# chown oracle:oinstall /tmp/oracle/patch.zip
# echo "extracting and installing Oracle Database Release Update 11.2.0.4.190115..."
# su oracle bash -c "unzip -o /tmp/oracle/patch.zip -d /tmp/oracle/" > /dev/null
# su oracle bash -c "cd /tmp/oracle/28729262 && opatch apply -force -silent -ocmrf /assets/ocm.rsp"
# rm -f /tmp/oracle/patch.zip

#download and extract SQL Developer CLI as workaround for SQL*Plus issues with "SET TERMOUT OFF/ON"
echo "downloading SQL Developer CLI..."
wget -q --no-check-certificate ${ORACLE_ASSETS}/sqlcl-19.2.1.206.1649.zip -O /tmp/sqlcl.zip
echo "extracting SQL Developer CLI..."
unzip /tmp/sqlcl.zip -d /opt > /dev/null
chown -R oracle:oinstall /opt/sqlcl
rm -f /tmp/sqlcl.zip

# # remove original sample schemas to save disk space
# rm -r -f ${ORACLE_HOME}/demo/schema
# # download and extract Oracle sample schemas
# echo "downloading Oracle sample schemas..."
# wget -q --no-check-certificate https://github.com/oracle/db-sample-schemas/archive/master.zip -O /tmp/db-sample-schemas-master.zip
# echo "extracting Oracle sample schemas..."
# unzip /tmp/db-sample-schemas-master.zip -d ${ORACLE_HOME}/demo/ > /dev/null
# mv ${ORACLE_HOME}/demo/db-sample-schemas-master ${ORACLE_HOME}/demo/schema
# # ensure ORACLE_HOME does not contain soft links to avoid "ORA-22288: file or LOB operation FILEOPEN failed"  (for Oracle sample schemas)
# ORACLE_HOME=`readlink -f ${ORACLE_HOME}`
# cd ${ORACLE_HOME}/demo/schema
# # replace placeholders in files, do not keep original version
# perl -p -i -e 's#__SUB__CWD__#'$(pwd)'#g' *.sql */*.sql */*.dat > /dev/null
# # reset environment (ORACLE_HOME)
# . /.oracle_env
# chown oracle:oinstall ${ORACLE_HOME}/demo/schema
# rm -f /tmp/db-sample-schemas-master.zip

# # rename original APEX folder (required for deinstallation of APEX)
# mv ${ORACLE_HOME}/apex ${ORACLE_HOME}/apex.old

# # download and extract APEX software
# echo "downloading APEX..."
# wget -q --no-check-certificate ${ORACLE_ASSETS}/apex_18.2_en.zip -O /tmp/apex.zip
# echo "extracting APEX..."
# unzip -o /tmp/apex.zip -d ${ORACLE_HOME} > /dev/null
# chown -R oracle:oinstall ${ORACLE_HOME}/apex
# rm -f /tmp/apex.zip

# # remove original ORDS folder to save disk space
# rm -r -f ${ORACLE_HOME}/ords

# # download and extract ORDS
# echo "downloading ORDS..."
# wget -q --no-check-certificate ${ORACLE_ASSETS}/ords-18.4.0.354.1002.zip -O /tmp/ords.zip
# echo "extracting ORDS..."
# mkdir /opt/ords
# unzip /tmp/ords.zip -d ${ORACLE_HOME}/ords/ > /dev/null
# chown -R oracle:oinstall ${ORACLE_HOME}/ords
# rm -f /tmp/ords.zip

# cleanup
rm -r -f /tmp/*
rm -r -f /var/tmp/*
