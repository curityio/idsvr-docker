#!/bin/bash

set -e

IMAGE_BASE="curity.azurecr.io/curity/idsvr"

build_multiplatform_image() {
  DISTRO=$1
  ARM_IMAGE="${IMAGE_BASE}:${VERSION}-${DISTRO}-arm"
  X86_IMAGE="${IMAGE_BASE}:${VERSION}-${DISTRO}-x86"

  for TAG in "${@:2}"
  do
      echo "creating manifest for $TAG with $ARM_IMAGE and $X86_IMAGE"
      docker manifest create "$TAG" "$ARM_IMAGE" "$X86_IMAGE"
      docker manifest push "$TAG"
      docker manifest rm "$TAG"
  done
}

if [[ "$VERSION" == *.0 ]]; then
  BRANCH_VERSION=${VERSION%??}
  EXTRA_TAGS_UBUNTU="${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu ${IMAGE_BASE}:${BRANCH_VERSION} ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu18 ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu18.04"
  EXTRA_TAGS_CENTOS="${IMAGE_BASE}:${BRANCH_VERSION}-centos8 ${IMAGE_BASE}:${BRANCH_VERSION}-centos"
  EXTRA_TAGS_BUSTER="${IMAGE_BASE}:${BRANCH_VERSION}-buster"
  EXTRA_TAGS_BUSTER_SLIM="${IMAGE_BASE}:${BRANCH_VERSION}-buster-slim ${IMAGE_BASE}:${BRANCH_VERSION}-slim"
fi

# shellcheck disable=SC2086
build_multiplatform_image "ubuntu" "${IMAGE_BASE}:${VERSION}-ubuntu18.04" "${IMAGE_BASE}:${VERSION}-ubuntu" "${IMAGE_BASE}:${VERSION}-ubuntu18" "${IMAGE_BASE}:${VERSION}" $EXTRA_TAGS_UBUNTU
# shellcheck disable=SC2086
build_multiplatform_image "centos" "${IMAGE_BASE}:${VERSION}-centos8" "${IMAGE_BASE}:${VERSION}-centos" $EXTRA_TAGS_CENTOS
# shellcheck disable=SC2086
build_multiplatform_image "buster" "${IMAGE_BASE}:${VERSION}-buster" $EXTRA_TAGS_BUSTER
# shellcheck disable=SC2086
build_multiplatform_image "buster-slim" "${IMAGE_BASE}:${VERSION}-buster-slim" "${IMAGE_BASE}:${VERSION}-slim" $EXTRA_TAGS_BUSTER_SLIM
