# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database 11g Release 2.0.4
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p13390677_112040_Linux-x86-64_1of7.zip
# (2) p13390677_112040_Linux-x86-64_2of7.zip
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/database:11.2.0.4-${EDITION} . 
#
# Pull base image
# ---------------
FROM oraclelinux:7-slim as base

# Maintainer
# ----------
LABEL MAINTAINER="Eric CLEMENT <eric.clement@juxta.fr>"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
#ENV ASSETS_LOCATION=./assets
ENV ASSETS_LOCATION=http://jxt-dev-pgsql.juxta.fr/oracle-assets
#ENV ASSETS_LOCATION=http://192.168.2.188/oracle-assets

ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/11.2.0/dbhome_1 \
    INSTALL_DIR=/opt/install \
    INSTALL_FILE_1="p13390677_112040_Linux-x86-64_1of7.zip" \
    INSTALL_FILE_2="p13390677_112040_Linux-x86-64_2of7.zip" \
    INSTALL_RSP="db_inst.rsp" \
    PWD_FILE="setPassword.sh" \
    RUN_FILE="runOracle.sh" \
    START_FILE="startDB.sh" \
    CREATE_DB_FILE="createDB.sh" \
    SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    CHECK_SPACE_FILE="checkSpace.sh" \
    CHECK_DB_FILE="checkDBStatus.sh" \
    USER_SCRIPTS_FILE="runUserScripts.sh" \
    INSTALL_DB_BINARIES_FILE="installDBBinaries.sh" \
    ORAENV_ASK=NO \
    ORACLE_SID=${ORACLE_SID:-ORCL} \
    ORACLE_MEM=""

# Use second ENV so that variable get substituted
ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

# Copy files needed during both installation and runtime
# -------------
COPY ./scripts/$SETUP_LINUX_FILE ./scripts/$CHECK_SPACE_FILE $INSTALL_DIR/
COPY ./scripts/$RUN_FILE ./scripts/$START_FILE ./scripts/$CREATE_DB_FILE ./scripts/$PWD_FILE ./scripts/$CHECK_DB_FILE ./scripts/$USER_SCRIPTS_FILE $ORACLE_BASE/

RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$CHECK_SPACE_FILE && \
    $INSTALL_DIR/$SETUP_LINUX_FILE && \
    rm -rf $INSTALL_DIR

#############################################
# -------------------------------------------
# Start new stage for installing the database
# -------------------------------------------
#############################################

FROM base AS builder

# Install unzip for unzip operation
RUN yum -y install oracle-epel-release-el7.x86_64
RUN yum -y install unzip
RUN yum -y install p7zip.x86_64

# Copy DB install file
ADD  ${ASSETS_LOCATION}/$INSTALL_FILE_1 $INSTALL_DIR/
ADD  ${ASSETS_LOCATION}/$INSTALL_FILE_2 $INSTALL_DIR/
RUN  chown -R oracle:oinstall $INSTALL_DIR/
COPY --chown=oracle:oinstall ./assets/$INSTALL_RSP ./scripts/$INSTALL_DB_BINARIES_FILE $INSTALL_DIR/

# Install DB software binaries
USER oracle
RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$INSTALL_DB_BINARIES_FILE

HEALTHCHECK --interval=1m --start-period=5m \
   CMD "$ORACLE_BASE/$CHECK_DB_FILE" >/dev/null || exit 1

#############################################
# -------------------------------------------
# Start new layer for database runtime
# -------------------------------------------
#############################################

FROM base AS database

USER oracle
COPY --chown=oracle:oinstall --from=builder $ORACLE_BASE $ORACLE_BASE

USER root
RUN $ORACLE_BASE/oraInventory/orainstRoot.sh && \
    $ORACLE_HOME/root.sh && \
    yum -y install oracle-epel-release-el7.x86_64 && \
    yum -y install p7zip.x86_64    

USER oracle
WORKDIR /home/oracle

#Remove volume [https://medium.com/@ggajos/drop-db-startup-time-from-45-to-3-minutes-in-dockerized-oracle-19-3-0-552068593deb]
#VOLUME ["$ORACLE_BASE/oradata"]
EXPOSE 1521 1158
HEALTHCHECK --interval=1m --start-period=5m \
   CMD "$ORACLE_BASE/$CHECK_DB_FILE" >/dev/null || exit 1

# Define default command to start Oracle Database. 
CMD exec $ORACLE_BASE/$RUN_FILE
