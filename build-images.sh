#!/bin/bash

set -e

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE_BASE="curity.azurecr.io/curity/idsvr"
DOCKER_CONTEXT=${VERSION}
FORCE_BUILD=${FORCE_DISTRO:-none}

build_image() {
  IMAGE=$1
  DOCKERFILE=$2
  if [[ -f "${DOCKERFILE}" ]] ; then

    # Find the base image used in the dockerfile
    BASE_IMAGE=$(cat "${DOCKERFILE}" | grep FROM | tail -1 | sed -e 's/FROM[[:space:]]//g')
    echo "BASE_IMAGE: ${BASE_IMAGE}"

    # Get the last layer id of the base image
    BASE_IMAGE_LAST_LAYER_ID=$(docker inspect "${BASE_IMAGE}" | jq ".[0].RootFS.Layers[-1]")
    echo "BASE_IMAGE_LAST_LAYER_ID: ${BASE_IMAGE_LAST_LAYER_ID}"

    # Download the current published image and inspect it
    docker pull "${IMAGE}" || true
    IMAGE_INSPECT=$(docker inspect "${IMAGE}" || true)

    # Check if the last layer of the base image exists in the published one
    if [[ $IMAGE_INSPECT != *$BASE_IMAGE_LAST_LAYER_ID* ]] || [[ $FORCE_UPDATE_VERSION == *$VERSION* ]] ||
       [[ $DOCKERFILE == *$FORCE_BUILD* ]]; then
      ARTIFACT=linux "$D"/download-release.sh

      # Build the image again
      docker build --no-cache -t "${IMAGE}" -f "${DOCKERFILE}" "${DOCKER_CONTEXT}"

      #Run sanity tests if RUN_SANITY_CHECK is set
      MAJOR_VERSION=(${VERSION//./ }[0])
      if [[ -n "${RUN_SANITY_CHECK}" ]] && [[ ${MAJOR_VERSION} -ge 5 ]] ; then
        echo "Running Sanity tests on image: ${IMAGE}"
        ./../tests/sanity-tests.sh 1 curity-idsvr admin Password1 ${IMAGE};
      fi

      #Run bats test if RUN_BATS_TEST is set
      if [[ -n "${RUN_BATS_TEST}" ]] ; then
        echo "Running Bats tests on image: ${IMAGE}"
        export BATS_CURITY_IMAGE=${IMAGE}
        tests/bats/bin/bats tests
      fi

      if [[ -n "${PUSH_IMAGES}" ]] ; then
        echo "Pushing image: ${IMAGE}"
        docker push "${IMAGE}";
      fi

      for TAG in "${@:3}"
      do
        docker tag "${IMAGE}" "${TAG}"
        if [[ -n "${PUSH_IMAGES}" ]] ; then
          echo "Pushing image: ${TAG}"
          docker push "${TAG}";
        fi
      done
    else
      echo "Skip pushing ${IMAGE} because it is unchanged"
    fi
  fi
}

BRANCH_VERSION=${VERSION%??}

CENTOS_VERSION="centos7"
if [ "${BRANCH_VERSION}" = "6.7" ] || [ "${BRANCH_VERSION}" = "6.8" ]; then
  CENTOS_VERSION="centos8"
fi

EXTRA_TAGS_UBUNTU="${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu ${IMAGE_BASE}:${BRANCH_VERSION} ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu18 ${IMAGE_BASE}:${BRANCH_VERSION}-ubuntu18.04"
EXTRA_TAGS_CENTOS="${IMAGE_BASE}:${BRANCH_VERSION}-${CENTOS_VERSION} ${IMAGE_BASE}:${BRANCH_VERSION}-centos"
EXTRA_TAGS_BUSTER="${IMAGE_BASE}:${BRANCH_VERSION}-buster"
EXTRA_TAGS_BUSTER_SLIM="${IMAGE_BASE}:${BRANCH_VERSION}-buster-slim ${IMAGE_BASE}:${BRANCH_VERSION}-slim"

build_image "${IMAGE_BASE}:${VERSION}-ubuntu18.04" "${VERSION}/ubuntu/Dockerfile" "${IMAGE_BASE}:${VERSION}-ubuntu" "${IMAGE_BASE}:${VERSION}-ubuntu18" "${IMAGE_BASE}:${VERSION}" $EXTRA_TAGS_UBUNTU
build_image "${IMAGE_BASE}:${VERSION}-${CENTOS_VERSION}" "${VERSION}/centos/Dockerfile" "${IMAGE_BASE}:${VERSION}-centos" $EXTRA_TAGS_CENTOS
build_image "${IMAGE_BASE}:${VERSION}-buster" "${VERSION}/buster/Dockerfile" $EXTRA_TAGS_BUSTER
build_image "${IMAGE_BASE}:${VERSION}-buster-slim" "${VERSION}/buster-slim/Dockerfile" "${IMAGE_BASE}:${VERSION}-slim" $EXTRA_TAGS_BUSTER_SLIM
