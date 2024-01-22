#!/bin/bash

set -e

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE_BASE="curity.azurecr.io/curity/idsvr"

[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1;

UBUNTU_22=ubuntu:22.04
CENTOS_8=quay.io/centos/centos:stream8 # Keep for version 8.x
CENTOS_9=quay.io/centos/centos:stream9
BUSTER=buildpack-deps:buster # Keep for version 8.x
BUSTER_SLIM=debian:buster-slim # Keep for version 8.x
BOOKWORM=debian:bookworm
BOOKWORM_SLIM=debian:bookworm-slim

# Pull x86 base images once to avoid pull limit in dockerhub
docker pull "$UBUNTU_22" --platform linux/amd64
docker pull "$CENTOS_8" --platform linux/amd64
docker pull "$CENTOS_9" --platform linux/amd64
docker pull "$BUSTER" --platform linux/amd64
docker pull "$BUSTER_SLIM" --platform linux/amd64
docker pull "$BOOKWORM" --platform linux/amd64
docker pull "$BOOKWORM_SLIM" --platform linux/amd64

UBUNTU_X86_LAST_LAYER_ID=$(docker inspect "${UBUNTU_22}" | jq ".[0].RootFS.Layers[-1]"); export UBUNTU_X86_LAST_LAYER_ID
CENTOS_X86_LAST_LAYER_ID=$(docker inspect "${CENTOS_8}" | jq ".[0].RootFS.Layers[-1]"); export CENTOS_X86_LAST_LAYER_ID
CENTOS9_X86_LAST_LAYER_ID=$(docker inspect "${CENTOS_9}" | jq ".[0].RootFS.Layers[-1]"); export CENTOS9_X86_LAST_LAYER_ID
BUSTER_X86_LAST_LAYER_ID=$(docker inspect "${BUSTER}" | jq ".[0].RootFS.Layers[-1]"); export BUSTER_X86_LAST_LAYER_ID
BUSTER_SLIM_X86_LAST_LAYER_ID=$(docker inspect "${BUSTER_SLIM}" | jq ".[0].RootFS.Layers[-1]"); export BUSTER_SLIM_X86_LAST_LAYER_ID
BOOKWORM_X86_LAST_LAYER_ID=$(docker inspect "${BOOKWORM}" | jq ".[0].RootFS.Layers[-1]"); export BOOKWORM_X86_LAST_LAYER_ID
BOOKWORM_SLIM_X86_LAST_LAYER_ID=$(docker inspect "${BOOKWORM_SLIM}" | jq ".[0].RootFS.Layers[-1]"); export BOOKWORM_SLIM_X86_LAST_LAYER_ID

# Pull ARM base images once to avoid pull limit in dockerhub
docker pull "$UBUNTU_22" --platform linux/arm64
docker pull "$CENTOS_8" --platform linux/arm64
docker pull "$CENTOS_9" --platform linux/arm64
docker pull "$BUSTER" --platform linux/arm64
docker pull "$BUSTER_SLIM" --platform linux/arm64
docker pull "$BOOKWORM" --platform linux/arm64
docker pull "$BOOKWORM_SLIM" --platform linux/arm64

UBUNTU_ARM_LAST_LAYER_ID=$(docker inspect "${UBUNTU_22}" | jq ".[0].RootFS.Layers[-1]"); export UBUNTU_ARM_LAST_LAYER_ID
CENTOS_ARM_LAST_LAYER_ID=$(docker inspect "${CENTOS_8}" | jq ".[0].RootFS.Layers[-1]"); export CENTOS_ARM_LAST_LAYER_ID
CENTOS9_ARM_LAST_LAYER_ID=$(docker inspect "${CENTOS_9}" | jq ".[0].RootFS.Layers[-1]"); export CENTOS9_ARM_LAST_LAYER_ID
BUSTER_ARM_LAST_LAYER_ID=$(docker inspect "${BUSTER}" | jq ".[0].RootFS.Layers[-1]"); export BUSTER_ARM_LAST_LAYER_ID
BUSTER_SLIM_ARM_LAST_LAYER_ID=$(docker inspect "${BUSTER_SLIM}" | jq ".[0].RootFS.Layers[-1]"); export BUSTER_SLIM_ARM_LAST_LAYER_ID
BOOKWORM_ARM_LAST_LAYER_ID=$(docker inspect "${BOOKWORM}" | jq ".[0].RootFS.Layers[-1]"); export BOOKWORM_ARM_LAST_LAYER_ID
BOOKWORM_SLIM_ARM_LAST_LAYER_ID=$(docker inspect "${BOOKWORM_SLIM}" | jq ".[0].RootFS.Layers[-1]"); export BOOKWORM_SLIM_ARM_LAST_LAYER_ID

docker buildx create --use
while IFS= read -r VERSION
do
  VERSION=${VERSION} "$D"/build-multiplatform-images.sh
done < <(find -- * -name "[0-9].[0-9].[0-9]" -type d | sort -r)

# Delete stopped containers and images
docker buildx prune -af && docker buildx rm
docker ps -a | awk '{ print $1,$2 }' | grep "${IMAGE_BASE}" | awk '{print $1 }' | xargs -I {} docker rm {}
docker images | awk '{ print $1,$3 }' | grep "${IMAGE_BASE}" | awk '{print $2 }' | xargs -I {} docker rmi {} --force
