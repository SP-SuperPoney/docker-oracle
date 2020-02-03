#!/bin/bash
BUILD_START=$(date '+%s')
CONTAINER_NAME="juxta-oracle-build-${BUILD_START}"

if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=${CONTAINER_NAME})" ]; then
        # cleanup
        docker rm ${CONTAINER_NAME}
    fi

    echo "Running Oracle Database 11gR2 Standard Edition in a Docker container"
    docker run -d --name ${CONTAINER_NAME} -e ORACLE_PWD=juxta -v ${PWD}/scripts/setup:/opt/oracle/scripts/setup juxta/oracle:11.2.0.4-se
fi

CONTAINER_STATUS=""
while test $CONTAINER_STATUS=""
  do CONTAINER_STATUS=`docker logs ${CONTAINER_NAME} 2>&1 | grep 'DATABASE IS READY TO USE!\|DATABASE SETUP WAS NOT SUCCESSFUL!'`
done


if [ "$CONTAINER_STATUS" = "DATABASE SETUP WAS NOT SUCCESSFUL!" ]
then
  echo "$CONTAINER_STATUS"
  docker rm -f ${CONTAINER_NAME}
  exit 1
fi

echo "Commit the container"
docker commit --author "Eric Clement <eric.clement@juxta.fr>" --message "Empty snapshot" ${CONTAINER_NAME} juxta/oracle:latest

echo "Push image to regisry (jxt-dev-pgsql.juxta.fr:5000/oracle)"

docker tag juxta/oracle jxt-dev-pgsql.juxta.fr:5000/oracle
docker push jxt-dev-pgsql.juxta.fr:5000/oracle

docker rm -f ${CONTAINER_NAME}
BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""
echo "Build completed in $BUILD_ELAPSED seconds."

exit 0
