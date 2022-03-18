#!/bin/bash

set -e

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE_BASE="curity.azurecr.io/curity/idsvr"

[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1;

UBUNTU_18=ubuntu:18.04
CENTOS_8=quay.io/centos/centos:stream8
BUSTER=buildpack-deps:buster
BUSTER_SLIM=debian:buster-slim

# Pull x86 base images once to avoid pull limit in dockerhub
docker pull "$UBUNTU_18" --platform linux/amd64
docker pull "$CENTOS_8" --platform linux/amd64
docker pull "$BUSTER" --platform linux/amd64
docker pull "$BUSTER_SLIM" --platform linux/amd64

UBUNTU_X86_LAST_LAYER_ID=$(docker inspect "${UBUNTU_18}" | jq ".[0].RootFS.Layers[-1]"); export UBUNTU_X86_LAST_LAYER_ID
CENTOS_X86_LAST_LAYER_ID=$(docker inspect "${CENTOS_8}" | jq ".[0].RootFS.Layers[-1]"); export CENTOS_X86_LAST_LAYER_ID
BUSTER_X86_LAST_LAYER_ID=$(docker inspect "${BUSTER}" | jq ".[0].RootFS.Layers[-1]"); export BUSTER_X86_LAST_LAYER_ID
BUSTER_SLIM_X86_LAST_LAYER_ID=$(docker inspect "${BUSTER_SLIM}" | jq ".[0].RootFS.Layers[-1]"); export BUSTER_SLIM_X86_LAST_LAYER_ID

# Pull ARM base images once to avoid pull limit in dockerhub
docker pull $UBUNTU_18--platform linux/arm64
docker pull $CENTOS_8 --platform linux/arm64
docker pull $BUSTER --platform linux/arm64
docker pull $BUSTER_SLIM--platform linux/arm64

UBUNTU_ARM_LAST_LAYER_ID=$(docker inspect "${UBUNTU_18}" | jq ".[0].RootFS.Layers[-1]"); export UBUNTU_ARM_LAST_LAYER_ID
CENTOS_ARM_LAST_LAYER_ID=$(docker inspect "${CENTOS_8}" | jq ".[0].RootFS.Layers[-1]"); export CENTOS_ARM_LAST_LAYER_ID
BUSTER_ARM_LAST_LAYER_ID=$(docker inspect "${BUSTER}" | jq ".[0].RootFS.Layers[-1]"); export BUSTER_ARM_LAST_LAYER_ID
BUSTER_SLIM_ARM_LAST_LAYER_ID=$(docker inspect "${BUSTER_SLIM}" | jq ".[0].RootFS.Layers[-1]"); export BUSTER_SLIM_ARM_LAST_LAYER_ID

docker buildx create --use
while IFS= read -r VERSION
do
if ! [[ "$VERSION" < "7.0.0" ]]; then
  VERSION=${VERSION} "$D"/build-multiplatform-images.sh
fi
done < <(find -- * -name "[0-9].[0-9].[0-9]" -type d | sort -r)

# Delete stopped containers and images
docker buildx prune -af && docker buildx rm
docker ps -a | awk '{ print $1,$2 }' | grep "${IMAGE_BASE}" | awk '{print $1 }' | xargs -I {} docker rm {}
docker images | awk '{ print $1,$3 }' | grep "${IMAGE_BASE}" | awk '{print $2 }' | xargs -I {} docker rmi {} --force
