#!/bin/bash

set -e

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE_BASE="curity.azurecr.io/curity/idsvr"
DOCKER_CONTEXT="$D/$VERSION"
LATEST_VERSION=$(find -- * -maxdepth 0 -type d | sort -rh | head -n 1)
FORCE_BUILD=${FORCE_DISTRO:-none}

build_multiplatform_image() {
  DOCKERFILE=$1
  X86_LAYER_ID=$2
  ARM_LAYER_ID=$3

  docker pull "$4" --platform linux/amd64 || true
  X86_IMAGE_INSPECT=$(docker inspect "$4" || true)

  docker pull "$4" --platform linux/arm64 || true
  ARM_IMAGE_INSPECT=$(docker inspect "$4" || true)


  if [[ $X86_IMAGE_INSPECT != *$X86_LAYER_ID* ]] || [[ $ARM_IMAGE_INSPECT != *$ARM_LAYER_ID* ]] ||
     [[ $DOCKERFILE == *$FORCE_BUILD* ]] || [[ $FORCE_UPDATE_VERSION == *$VERSION* ]]; then

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

if [[ "$VERSION" == "$LATEST_VERSION" ]]; then LATEST_TAG="${IMAGE_BASE}:latest"; else LATEST_TAG=""; fi

BRANCH_VERSION=${VERSION%??}
MAJOR_VERSION=${BRANCH_VERSION%??}

if [ "${MAJOR_VERSION}" == "7" ]; then
  EXTRA_TAGS_UBUNTU="${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu ${IMAGE_BASE}:${BRANCH_VERSION} ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu18 ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu18.04"
  build_multiplatform_image "${VERSION}/ubuntu/Dockerfile" "$UBUNTU_18_X86_LAST_LAYER_ID" "$UBUNTU_18_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-ubuntu18.04" "${IMAGE_BASE}:${VERSION}-ubuntu" "${IMAGE_BASE}:${VERSION}-ubuntu18" "${IMAGE_BASE}:${VERSION}" $LATEST_TAG $EXTRA_TAGS_UBUNTU
else
  EXTRA_TAGS_UBUNTU="${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu ${IMAGE_BASE}:${BRANCH_VERSION} ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu22 ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu22.04"
  build_multiplatform_image "${VERSION}/ubuntu/Dockerfile" "$UBUNTU_X86_LAST_LAYER_ID" "$UBUNTU_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-ubuntu22.04" "${IMAGE_BASE}:${VERSION}-ubuntu" "${IMAGE_BASE}:${VERSION}-ubuntu22" "${IMAGE_BASE}:${VERSION}" $LATEST_TAG $EXTRA_TAGS_UBUNTU
fi

EXTRA_TAGS_CENTOS="${IMAGE_BASE}:${BRANCH_VERSION}-centos8 ${IMAGE_BASE}:${BRANCH_VERSION}-centos"
build_multiplatform_image "${VERSION}/centos/Dockerfile" "$CENTOS_X86_LAST_LAYER_ID" "$CENTOS_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-centos8" "${IMAGE_BASE}:${VERSION}-centos" $EXTRA_TAGS_CENTOS

EXTRA_TAGS_BUSTER="${IMAGE_BASE}:${BRANCH_VERSION}-buster"
build_multiplatform_image "${VERSION}/buster/Dockerfile" "$BUSTER_X86_LAST_LAYER_ID" "$BUSTER_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-buster" $EXTRA_TAGS_BUSTER

EXTRA_TAGS_BUSTER_SLIM="${IMAGE_BASE}:${BRANCH_VERSION}-buster-slim ${IMAGE_BASE}:${BRANCH_VERSION}-slim"
build_multiplatform_image "${VERSION}/buster-slim/Dockerfile" "$BUSTER_SLIM_X86_LAST_LAYER_ID" "$BUSTER_SLIM_ARM_LAST_LAYER_ID" "${IMAGE_BASE}:${VERSION}-buster-slim" "${IMAGE_BASE}:${VERSION}-slim" $EXTRA_TAGS_BUSTER_SLIM
