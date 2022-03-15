#!/bin/bash

set -e

LATEST_RELEASE=$(find -- * -maxdepth 0 -type d | sort -rh | head -n 1)

ARM_IMAGE="curity.azurecr.io/curity/idsvr:${LATEST_RELEASE}-arm"
X86_IMAGE="curity.azurecr.io/curity/idsvr:${LATEST_RELEASE}-x86"
LATEST_TAG="curity.azurecr.io/curity/idsvr:latest"

docker pull "$ARM_IMAGE"
docker pull "$X86_IMAGE"

CURRENT_LATEST_MULTIPLATFORM_MANIFEST=$(docker manifest inspect "${LATEST_TAG}")
LATEST_ARM_IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "${ARM_IMAGE}" | sed "s/.*sha256://g")
LATEST_X86_IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "${X86_IMAGE}" | sed "s/.*sha256://g")


if [[ $CURRENT_LATEST_MULTIPLATFORM_MANIFEST != *$LATEST_ARM_IMAGE_DIGEST*  || $CURRENT_LATEST_MULTIPLATFORM_MANIFEST != *$LATEST_X86_IMAGE_DIGEST* ]]; then
  if [[ -n "${PUSH_IMAGES}" ]] ; then
    echo "Pushing image: $LATEST_TAG"
    docker manifest rm "$LATEST_TAG" || true
    docker manifest create "$LATEST_TAG" "$ARM_IMAGE" "$X86_IMAGE"
    docker manifest push "$LATEST_TAG"
  fi
fi

docker rmi "$ARM_IMAGE" "$X86_IMAGE" "$LATEST_TAG" || true