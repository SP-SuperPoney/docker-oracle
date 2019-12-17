FROM oracle/11.2.0.4:base

LABEL maintainer="eric.clement@juxta.fr"
LABEL description="Oracle Database 11.2.0.4 db"
LABEL build.command="docker build . --tag oracle/11.2.0.4:db"
LABEL run.command="docker run -v oracle:/u02 -it -p 1158:1158 -p 8081:8081 -p 1521:1521 -h oracle --name oracle oracle/11.2.0.4:base"

# environment variables (defaults for DBCA and entrypoint.sh)
ENV DBCONTROL=true \
    DBCA_TOTAL_MEMORY=2048 \
    GDBNAME=oracle.docker \
    ORACLE_SID=oracle \
    SERVICE_NAME=oracle.docker \
    PASS=oracle

# copy all scripts
ADD assets /assets/

# database port, Enterprise Manager Database Control port
EXPOSE 1521 1158

# all data directories in /u01 are linked to this volume
VOLUME ["/u02"]

# entrypoint for database creation, startup and graceful shutdown
ENTRYPOINT ["/assets/entrypoint.sh"]
CMD [""]
