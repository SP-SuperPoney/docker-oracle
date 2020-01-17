FROM jxt-dev-pgsql.juxta.fr:5000/oracle-db

LABEL maintainer="eric.clement@juxta.fr"
LABEL description="Oracle Database 11.2.0.4 run"
LABEL build.command="docker build . --tag jxt-dev-pgsql.juxta.fr:5000/oracle-run"
LABEL run.command="docker run -v oracle:/u01 -it -p 1158:1158 -p 1521:1521 -h oracle --name oracle jxt-dev-pgsql.juxta.fr:5000/oracle-db"

# environment variables (defaults for DBCA and entrypoint.sh)
ENV DBCONTROL=true
ENV DBCA_TOTAL_MEMORY=2048
ENV GDBNAME=oracle.docker
ENV ORACLE_SID=oracle
ENV SERVICE_NAME=oracle.docker
ENV PASS=oracle
ENV ORACLE_ASSETS=http://jxt-dev-pgsql.juxta.fr/oracle-assets
ENV DUMPFILE=expdp.dmp
ENV RUN_SCRIPTS_IN_SCHEMA=FSV
ENV SCRIPTS_ROOT=/patch/fsv

# copy all scripts
ADD assets /assets/

# database port, Enterprise Manager Database Control port
EXPOSE 1521 1158

# all data directories in /u01 are linked to this volume
VOLUME ["/u01"]

# entrypoint for database creation, startup and graceful shutdown
ENTRYPOINT ["/assets/entrypoint.sh"]
CMD [""]
