#!/bin/bash
BUILD_START=$(date '+%s')

docker rm juxta-oracle-ref

echo "Running Oracle Database 11gR2 Standard Edition in a Docker container"
docker run -d --name juxta-oracle-ref -p 1158:1158/tcp -p 1521:1521/tcp -e ORACLE_PWD=juxta -v ${PWD}/scripts/setup:/opt/oracle/scripts/setup juxta/oracle:11.2.0.4-se


CONTAINER_STATUS=""
while test $CONTAINER_STATUS=""
  do CONTAINER_STATUS=`docker logs juxta-oracle-ref 2>&1 | grep 'DATABASE IS READY TO USE!\|DATABASE SETUP WAS NOT SUCCESSFUL!'`
done


if [ "$CONTAINER_STATUS" = "DATABASE SETUP WAS NOT SUCCESSFUL!" ]
then
  echo "$CONTAINER_STATUS"
  docker rm -f juxta-oracle-ref
  exit 1
fi

echo "Commit the container"
docker commit --author "Eric Clement <eric.clement@juxta.fr>" --message "Empty snapshot" juxta-oracle-ref juxta/oracle:latest

echo "Push image to regisry (jxt-dev-pgsql.juxta.fr:5000/oracle)"

docker tag juxta/oracle jxt-dev-pgsql.juxta.fr:5000/oracle
docker push jxt-dev-pgsql.juxta.fr:5000/oracle

docker rm -f juxta-oracle-ref
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""
echo "Build completed in $BUILD_ELAPSED seconds."


