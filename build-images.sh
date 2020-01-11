#!/bin/bash

set -e

DATE=$(/bin/date +%Y%m%d)

DOCKER_CONTEXT=${VERSION}

build_image() {
  IMAGE=$1
  DOCKERFILE=$2

  # Download the current published image and store its ID
  docker pull "${IMAGE}" || true
  CURRENT_PUBLISHED_IMAGE_ID=$(docker images --filter=reference="${IMAGE}" --format "{{.ID}}")

  # Build the image again (it should use cache if the base layer is the same)
  docker build -t "${IMAGE}" -f "${DOCKERFILE}" "${DOCKER_CONTEXT}"

  # Compare the newly built image with the published one
  BUILT_IMAGE_ID=$(docker images --filter=reference="${IMAGE}" --format "{{.ID}}")
  if [[ "${BUILT_IMAGE_ID}" != "${CURRENT_PUBLISHED_IMAGE_ID}" ]]; then
    if [[ -n "${PUSH_IMAGES}" ]] ; then docker push "${IMAGE}"; fi

    # Update the extra tags
    docker tag "${IMAGE}" "${IMAGE}-${DATE}"
    if [[ -n "${PUSH_IMAGES}" ]] ; then 
      echo "Pushing image: ${IMAGE}-${DATE}"
      docker push "${IMAGE}-${DATE}"; 
    fi

    for TAG in "${@:3}"
    do
      docker tag "${IMAGE}" "${TAG}"
      if [[ -n "${PUSH_IMAGES}" ]] ; then
        echo "Pushing image: ${TAG}"
        docker push "${TAG}"; 
      fi
    done

  fi
}

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CENTOS_DIR=$D/$VERSION/centos
CENTOS_BIN_DIR=$CENTOS_DIR/bin
CENTOS_LIB_DIR=$CENTOS_DIR/lib
OPENSSL_BUILD_DIR=$D/openssl/build

$D/openssl/build-openssl.sh && \
  mkdir -p $CENTOS_BIN_DIR $CENTOS_LIB_DIR && \
  cp -a $OPENSSL_BUILD_DIR/bin/openssl $CENTOS_DIR/bin && \
  cp -a $OPENSSL_BUILD_DIR/lib/lib*.so* $CENTOS_DIR/lib

build_image "curity/idsvr:${VERSION}-ubuntu18.04" "${VERSION}/ubuntu/Dockerfile" "curity/idsvr:${VERSION}-ubuntu" "curity/idsvr:${VERSION}-ubuntu18" "curity/idsvr:${VERSION}"
build_image "curity/idsvr:${VERSION}-centos7" "${VERSION}/centos/Dockerfile" "curity/idsvr:${VERSION}-centos"
build_image "curity/idsvr:${VERSION}-stretch" "${VERSION}/stretch/Dockerfile"
build_image "curity/idsvr:${VERSION}-stretch-slim" "${VERSION}/stretch-slim/Dockerfile" "curity/idsvr:${VERSION}-slim"