#!/bin/bash

set -e

ARM_IMAGE="curity.azurecr.io/curity/idsvr:${VERSION}-arm"
X86_IMAGE="curity.azurecr.io/curity/idsvr:${VERSION}-x86"

docker pull "$ARM_IMAGE"
docker pull "$X86_IMAGE"


if [[ "$VERSION" == *.0 ]]; then
  BRANCH_VERSION=${VERSION%??}
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-ubuntu
  curity.azurecr.io/curity/idsvr:${BRANCH_VERSION} curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-ubuntu18
  curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-ubuntu18.04"
fi

# shellcheck disable=SC2206
TAG_ARRAY=("curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18.04" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu"
"curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18" "curity.azurecr.io/curity/idsvr:${VERSION}" $EXTRA_TAGS_UBUNTU)


for m in "${TAG_ARRAY[@]}"; do
  docker manifest create "$m" ARM_IMAGE X86_IMAGE
  docker manifest push "$m"
done
