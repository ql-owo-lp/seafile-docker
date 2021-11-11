#!/bin/bash

DOCKERFILE_DIR="."
MULTIARCH_PLATFORMS="linux/amd64"

USER="iowoi"
IMAGE="seafile"
SEAFILE_VERSION="8.0.7"
TAGS=""
BUILD_SEAFILE="0"
# When FORCE is not 0, built image cache will be deleted.
FORCE="0"

OUTPUT=""
while getopts "t:v:l:a:pbf" flag
do
    case "${flag}" in
        b) BUILD_SEAFILE="1";;
        v) SEAFILE_VERSION="$OPTARG";;
        t) TAGS="$TAGS -t $USER/$IMAGE:$OPTARG";;
        p) OUTPUT="--push";;
        l) OUTPUT="--load";;
        a) MULTIARCH_PLATFORMS="linux/$OPTARG";;
	f) FORCE="1";;
        :) exit;;
        \?) exit;; 
    esac
done

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

SEAFILE_VERSION_ARR=($(echo $SEAFILE_VERSION | tr "." "\n"))

trap '
  trap - INT # restore default INT handler
  kill -s INT "$$"
' INT

# Enable use of docker buildx
export DOCKER_CLI_EXPERIMENTAL=enabled

# Register qemu handlers
docker run --rm --privileged tonistiigi/binfmt --install all

# create multiarch builder if needed
BUILDER=multiarch_builder
if [ "$(docker buildx ls | grep $BUILDER)" == "" ]
then
    docker buildx create --name $BUILDER
fi

# Use the builder
docker buildx use $BUILDER

# Fix docker multiarch building when host local IP changes
BUILDER_CONTAINER="$(docker ps -qf name=$BUILDER)"
if [ ! -z "${BUILDER_CONTAINER}" ]; then
  if [ "${FORCE}" -eq "0" ]; then
    echo 'Restarting builder container..'
    docker restart "${BUILDER_CONTAINER}"
    sleep 10
  else
    echo 'Deleting builder container..'
    # This will clear built image cache.
    docker rm --force "${BUILDER_CONTAINER}"
   fi
fi

# Build image
docker buildx build $OUTPUT --platform "$MULTIARCH_PLATFORMS" --build-arg "SEAFILE_VERSION=${SEAFILE_VERSION}" --build-arg "BUILD_SEAFILE=${BUILD_SEAFILE}" -t "$USER/$IMAGE:${SEAFILE_VERSION}" -t "$USER/$IMAGE:${SEAFILE_VERSION_ARR[0]}" $TAGS "$DOCKERFILE_DIR"

export DOCKER_CLI_EXPERIMENTAL=disabled

cd -
