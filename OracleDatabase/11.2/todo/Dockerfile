FROM oracle11g:installed
LABEL maintainer=eric.clement@juxta.fr

ARG DUMP_FILE_ARG

ADD . /assets
COPY --chown=oracle:oinstall ./dump/ /opt/oracle/dpdump/

RUN chmod -R 755 /assets
RUN /assets/entrypoint.sh $DUMP_FILE_ARG
RUN rm -rf /opt/oracle/dpdump/*

EXPOSE 1521
EXPOSE 1158

CMD ["/assets/entrypoint.sh"]
