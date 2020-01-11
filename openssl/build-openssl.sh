#!/bin/bash
#
# Script that prepares the OpenSSL build agent (Docker container) and compiles OpenSSL inside it

set -e

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OPENSSL_VERSION=${OPENSSL_VERSION:-1_1_1d}
DOCKER_BUILD_AGENT_CONTEXT_DIR=$D/docker
OPENSSL_SRC_DIR=$D/src # Outside of the Docker context because it isn't in the build agent image
DOCKER_FILE=$D/Dockerfile-centos-build-agent
BUILD_AGENT_TAG_NAME=compile-openssl
BUILD_OUTPUT_DIR=$D/build

# If output dir is empty, we should rebuild. Try to delete dir if we can. If it's still there after
# it's because it contains files and we should exit.
rmdir $BUILD_OUTPUT_DIR 2>/dev/null |:

if [[ -d $BUILD_OUTPUT_DIR ]] ; then
	echo "Skipping build since $BUILD_OUTPUT_DIR exists. To rebuild, delete this directory first."
	exit 0
fi	

mkdir -p $DOCKER_BUILD_AGENT_CONTEXT_DIR $BUILD_OUTPUT_DIR
git clone --branch OpenSSL_${OPENSSL_VERSION} --depth 1 git://git.openssl.org/openssl.git $OPENSSL_SRC_DIR 2>/dev/null |:

# The source might have already been cloned, so make sure the source matches the expected version.
git -C $OPENSSL_SRC_DIR tag --list | grep -q $OPENSSL_VERSION || ( echo "Wrong SSL version already checked out" >&2 && exit 1 )

# Build the container that will be used to compile the source
cp -a $DOCKER_FILE $DOCKER_BUILD_AGENT_CONTEXT_DIR
cp -a $D/compile-openssl.sh $DOCKER_BUILD_AGENT_CONTEXT_DIR
docker build -t $BUILD_AGENT_TAG_NAME -f $DOCKER_FILE $DOCKER_BUILD_AGENT_CONTEXT_DIR

# Compile the source inside the build agent container. 
# The results will be in the build dir that is mounted in.
exec docker run \
	-it \
	-v $OPENSSL_SRC_DIR:/openssl \
	-v $BUILD_OUTPUT_DIR:/build \
	--workdir /openssl \
	$BUILD_AGENT_TAG_NAME
