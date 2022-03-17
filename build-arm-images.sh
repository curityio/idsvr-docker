#!/bin/bash

set -e

IMAGE_BASE="curity.azurecr.io/curity/idsvr"
DOCKER_CONTEXT=${VERSION}

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
    if [[ $IMAGE_INSPECT != *$BASE_IMAGE_LAST_LAYER_ID* ]]  || [[ $FORCE_UPDATE_VERSION == *$VERSION* ]]; then
      ARTIFACT=linux-arm ./download-release.sh

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

    else
      echo "Skip pushing ${IMAGE} because it is unchanged"
    fi
  fi
}

build_image "${IMAGE_BASE}:${VERSION}-ubuntu-arm" "${VERSION}/ubuntu/Dockerfile"
build_image "${IMAGE_BASE}:${VERSION}-centos-arm" "${VERSION}/centos/Dockerfile"
build_image "${IMAGE_BASE}:${VERSION}-buster-arm" "${VERSION}/buster/Dockerfile"
build_image "${IMAGE_BASE}:${VERSION}-buster-slim-arm" "${VERSION}/buster-slim/Dockerfile"
