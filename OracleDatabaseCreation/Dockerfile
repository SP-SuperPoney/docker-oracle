FROM jxt-dev-pgsql.juxta.fr:5000/oracle-base

LABEL maintainer="eric.clement@juxta.fr"
LABEL description="Oracle Database 11.2.0.4 db"
LABEL build.command="docker build . --tag jxt-dev-pgsql.juxta.fr:5000/oracle-db"
LABEL run.command="docker run -v oracle:/u01 -it -p 1158:1158 -p 1521:1521 -h oracle --name oracle jxt-dev-pgsql.juxta.fr:5000/oracle-base"

# environment variables (defaults for DBCA and entrypoint.sh)
ENV DBCONTROL=true \
    DBCA_TOTAL_MEMORY=2048 \
    GDBNAME=oracle.docker \
    ORACLE_SID=oracle \
    SERVICE_NAME=oracle.docker \
    PASS=oracle \
    DUMPFILE=expdp.dmp

# copy all scripts
COPY assets /assets/

# database port, Enterprise Manager Database Control port
EXPOSE 1521 1158

# all data directories in /u01 are linked to this volume
VOLUME ["/u01"]

# entrypoint for database creation, startup and graceful shutdown
ENTRYPOINT ["/assets/entrypoint.sh"]
CMD [""]
