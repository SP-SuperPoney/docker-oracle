#FROM oraclelinux:7.6
FROM oraclelinux:7-slim

LABEL maintainer="eric.clement@juxta.fr"
LABEL description="Oracle Database 11.2.0.4 database only"
LABEL build.command="docker build . --tag jxt-dev-pgsql.juxta.fr:5000/oracle-base"

# set download location for Oracle software which are not available for unattended downloads
ENV ORACLE_ASSETS=http://jxt-dev-pgsql.juxta.fr/oracle-assets
#ENV ORACLE_ASSETS=http://192.168.2.188/oracle-assets

# copy all scripts
COPY assets /assets/

# image setup via shell script to reduce layers and optimize final disk usage
RUN /assets/db_setup.sh
