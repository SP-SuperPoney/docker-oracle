#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com, eric.clement@juxta.fr (11.2.0.4 version)
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
echo -e "\033[32mstarting bash script $0\033[0m"

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------
mkdir -p $ORACLE_BASE/scripts/setup && \
mkdir -p $ORACLE_BASE/scripts/startup && \
ln -s $ORACLE_BASE/scripts /docker-entrypoint-initdb.d && \
mkdir $ORACLE_BASE/oradata && \
mkdir -p $ORACLE_HOME && \
chmod ug+x $ORACLE_BASE/*.sh && \
yum -y install oracle-rdbms-server-11gR2-preinstall openssl && \
rm -rf /var/cache/yum && \
ln -s $ORACLE_BASE/$PWD_FILE /home/oracle/ && \
echo oracle:oracle | chpasswd && \
chown -R oracle:oinstall $ORACLE_BASE && \
usermod -a -G oinstall oracle

echo "Change timezone to Central European Time (CET)."
unlink /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Brussels /etc/localtime

# Workaround to improve startup time of DBCA
# remove domain entry, see MOS Doc ID 362092.1
cp /etc/resolv.conf /etc/resolv.conf.ori
sed 's/domain.*//' /etc/resolv.conf.ori > /etc/resolv.conf
