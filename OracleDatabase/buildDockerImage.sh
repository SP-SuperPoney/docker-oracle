#!/bin/bash

usage() {
  cat << EOF

Usage: buildDockerImage.sh [-o] [-d] [-t target] [Docker build option]
Builds a Docker Image for Oracle Database.
  
Parameters:
   -d: debug mode, do not remove dangling images (intermitten images with tag <none>)
   -t: target a specific intermitten images (base, builder, database)
   -o: passes on Docker build option
   -h: usage

EOF

}

# Check Docker version
checkDockerVersion() {
  # Get Docker Server version
  DOCKER_VERSION=$(docker version --format '{{.Server.Version | printf "%.5s" }}')
  # Remove dot in Docker version
  DOCKER_VERSION=${DOCKER_VERSION//./}

  if [ "$DOCKER_VERSION" -lt "${MIN_DOCKER_VERSION//./}" ]; then
    echo "Docker version is below the minimum required version $MIN_DOCKER_VERSION"
    echo "Please upgrade your Docker installation to proceed."
    exit 1;
  fi;
}

##############
#### MAIN ####
##############

# Parameters
DEBUG=0
STANDARD=1
VERSION="11.2.0.4"
DOCKEROPS="--force-rm=true --no-cache=true"
MIN_DOCKER_VERSION="17.09"
DOCKERFILE="Dockerfile"
EDITION="se"
TARGET=""

while getopts "h:dto:" optname; do
  case "$optname" in
    "h")
      usage
      exit 0;
      ;;
    "t")
      TARGET=${TARGET}
      ;;       
    "d")
      DEBUG=1
      DOCKEROPS=""
      ;;      
    "o")
      DOCKEROPS="${DOCKEROPS} ${OPTARG}"
      ;;
    "?")
      usage;
      exit 1;
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

checkDockerVersion

#Image Name
IMAGE_NAME="juxta/oracle:$VERSION-$EDITION"
echo "=========================="
echo "DOCKER info:"
docker info
echo "=========================="

# Proxy settings
PROXY_SETTINGS=""
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during the build."
fi

# ################## #
# BUILDING THE IMAGE #
# ################## #
echo "Building image '$IMAGE_NAME' ..."

# BUILD THE IMAGE (replace all environment variables)
BUILD_START=$(date '+%s')
docker build \
       $DOCKEROPS $PROXY_SETTINGS $TARGET --build-arg DB_EDITION=$EDITION \
       -t $IMAGE_NAME -f $DOCKERFILE . || {
  echo ""
  echo "ERROR: Oracle Database Docker Image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the docker build operation."
  exit 1
}

if [ ! "$DEBUG" -eq 1 ]; then
  echo "Keep dangling images (intermitten images with tag <none>)."
else
  echo "Remove dangling images (intermitten images with tag <none>)"
  yes | docker image prune > /dev/null  
fi


BUILD_END=$(date '+%s')
BUILD_ELAPSED=`expr $BUILD_END - $BUILD_START`

echo ""
echo ""

cat << EOF
  Oracle Database Docker Image for '$EDITION' version $VERSION is ready to be extended: 
    
    --> $IMAGE_NAME

  Build completed in $BUILD_ELAPSED seconds.
  
EOF

