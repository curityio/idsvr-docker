#!/bin/bash

set -e

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE_BASE="curity.azurecr.io/curity/idsvr"
DOCKER_CONTEXT="$D/$VERSION"
LATEST_VERSION=$(find -- * -maxdepth 0 -type d | sort -rh | head -n 1)

build_multiplatform_image() {
  DOCKERFILE=$1
  X86_LAYER_ID=$2
  ARM_LAYER_ID=$3

  docker pull "$4" --platform linux/amd64 || true
  X86_IMAGE_INSPECT=$(docker inspect "$4" || true)

  docker pull "$4" --platform linux/arm64 || true
  ARM_IMAGE_INSPECT=$(docker inspect "$4" || true)


  if [[ $X86_IMAGE_INSPECT != *$X86_LAYER_ID* ]] || [[ $ARM_IMAGE_INSPECT != *$ARM_LAYER_ID* ]] ||
     [[ $FORCE_DISTRO == *$DOCKERFILE* ]] || [[ $FORCE_UPDATE_VERSION == *$VERSION* ]]; then

    TARGET_ARCH=-amd64 ARTIFACT=linux "$D"/download-release.sh
    TARGET_ARCH=-arm64 ARTIFACT=linux-arm "$D"/download-release.sh

    for TAG in "${@:4}"
    do
        if [[ -n "${PUSH_IMAGES}" ]]; then PUSH="--push"; else PUSH=""; fi
        echo "Running docker buildx for tag: ${TAG} with parameters --platform linux/amd64,linux/arm64 ${PUSH}"
        docker buildx build --platform linux/amd64,linux/arm64 ${PUSH} -t "${TAG}" -f "${DOCKERFILE}" "${DOCKER_CONTEXT}"
    done
    else
      echo "$4 is based on the latest base image, skip building"
  fi
}

BRANCH_VERSION=${VERSION%??}
EXTRA_TAGS_UBUNTU="${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu ${IMAGE_BASE}:${BRANCH_VERSION} ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu18 ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu18.04"
EXTRA_TAGS_CENTOS="${IMAGE_BASE}:${BRANCH_VERSION}-centos8 ${IMAGE_BASE}:${BRANCH_VERSION}-centos"
EXTRA_TAGS_BUSTER="${IMAGE_BASE}:${BRANCH_VERSION}-buster"
EXTRA_TAGS_BUSTER_SLIM="${IMAGE_BASE}:${BRANCH_VERSION}-buster-slim ${IMAGE_BASE}:${BRANCH_VERSION}-slim"

if [[ "$VERSION" == "$LATEST_VERSION" ]]; then LATEST_TAG="${IMAGE_BASE}:latest"; else LATEST_TAG=""; fi

build_multiplatform_image "${VERSION}/ubuntu/Dockerfile" "$UBUNTU_X86_LAST_LAYER_ID" "$UBUNTU_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-ubuntu18.04" "${IMAGE_BASE}:${VERSION}-ubuntu" "${IMAGE_BASE}:${VERSION}-ubuntu18" "${IMAGE_BASE}:${VERSION}" $LATEST_TAG $EXTRA_TAGS_UBUNTU
build_multiplatform_image "${VERSION}/buster/Dockerfile" "$BUSTER_X86_LAST_LAYER_ID" "$BUSTER_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-buster" $EXTRA_TAGS_BUSTER
build_multiplatform_image "${VERSION}/buster-slim/Dockerfile" "$BUSTER_SLIM_X86_LAST_LAYER_ID" "$BUSTER_SLIM_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-buster-slim" "${IMAGE_BASE}:${VERSION}-slim" $EXTRA_TAGS_BUSTER_SLIM
build_multiplatform_image "${VERSION}/centos/Dockerfile" "$CENTOS_X86_LAST_LAYER_ID" "$CENTOS_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-centos8" "${IMAGE_BASE}:${VERSION}-centos" $EXTRA_TAGS_CENTOS
