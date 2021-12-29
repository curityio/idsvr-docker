#!/bin/bash

set -e

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
     ./download-release.sh

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

CENTOS_VERSION="centos8"
if [ "${VERSION}" = "5.0.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.0.0-ubuntu curity.azurecr.io/curity/idsvr:5.0.0 curity.azurecr.io/curity/idsvr:5.0.0-ubuntu18 curity.azurecr.io/curity/idsvr:5.0.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.0.0-centos7 curity.azurecr.io/curity/idsvr:5.0.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.0.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.0.0-buster-slim curity.azurecr.io/curity/idsvr:5.0.0-slim"
elif [ "${VERSION}" = "5.1.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.1.0-ubuntu curity.azurecr.io/curity/idsvr:5.1.0 curity.azurecr.io/curity/idsvr:5.1.0-ubuntu18 curity.azurecr.io/curity/idsvr:5.1.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.1.0-centos7 curity.azurecr.io/curity/idsvr:5.1.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.1.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.1.0-buster-slim curity.azurecr.io/curity/idsvr:5.1.0-slim"
elif [ "${VERSION}" = "5.2.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.2.0-ubuntu curity.azurecr.io/curity/idsvr:5.2.0 curity.azurecr.io/curity/idsvr:5.2.0-ubuntu18 curity.azurecr.io/curity/idsvr:5.2.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.2.0-centos7 curity.azurecr.io/curity/idsvr:5.2.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.2.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.2.0-buster-slim curity.azurecr.io/curity/idsvr:5.2.0-slim"
elif [ "${VERSION}" = "5.3.5" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.3.0-ubuntu curity.azurecr.io/curity/idsvr:5.3.0 curity.azurecr.io/curity/idsvr:5.3.0-ubuntu18 curity.azurecr.io/curity/idsvr:5.3.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.3.0-centos7 curity.azurecr.io/curity/idsvr:5.3.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.3.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.3.0-buster-slim curity.azurecr.io/curity/idsvr:5.3.0-slim"
elif [ "${VERSION}" = "5.4.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.4.0-ubuntu curity.azurecr.io/curity/idsvr:5.4.0 curity.azurecr.io/curity/idsvr:5.4.0-ubuntu18 curity.azurecr.io/curity/idsvr:5.4.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.4.0-centos7 curity.azurecr.io/curity/idsvr:5.4.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.4.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.4.0-buster-slim curity.azurecr.io/curity/idsvr:5.4.0-slim"
elif [ "${VERSION}" = "6.0.5" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.0.0-ubuntu curity.azurecr.io/curity/idsvr:6.0.0 curity.azurecr.io/curity/idsvr:6.0.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.0.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.0.0-centos7 curity.azurecr.io/curity/idsvr:6.0.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.0.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.0.0-buster-slim curity.azurecr.io/curity/idsvr:6.0.0-slim"
elif [ "${VERSION}" = "6.1.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.1.0-ubuntu curity.azurecr.io/curity/idsvr:6.1.0 curity.azurecr.io/curity/idsvr:6.1.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.1.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.1.0-centos7 curity.azurecr.io/curity/idsvr:6.1.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.1.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.1.0-buster-slim curity.azurecr.io/curity/idsvr:6.1.0-slim"
elif [ "${VERSION}" = "6.2.6" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.2.0-ubuntu curity.azurecr.io/curity/idsvr:6.2.0 curity.azurecr.io/curity/idsvr:6.2.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.2.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.2.0-centos7 curity.azurecr.io/curity/idsvr:6.2.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.2.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.2.0-buster-slim curity.azurecr.io/curity/idsvr:6.2.0-slim"
elif [ "${VERSION}" = "6.3.5" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.3.0-ubuntu curity.azurecr.io/curity/idsvr:6.3.0 curity.azurecr.io/curity/idsvr:6.3.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.3.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.3.0-centos7 curity.azurecr.io/curity/idsvr:6.3.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.3.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.3.0-buster-slim curity.azurecr.io/curity/idsvr:6.3.0-slim"
elif [ "${VERSION}" = "6.4.7" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.4.0-ubuntu curity.azurecr.io/curity/idsvr:6.4.0 curity.azurecr.io/curity/idsvr:6.4.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.4.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.4.0-centos7 curity.azurecr.io/curity/idsvr:6.4.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.4.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.4.0-buster-slim curity.azurecr.io/curity/idsvr:6.4.0-slim"
elif [ "${VERSION}" = "6.5.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.5.0-ubuntu curity.azurecr.io/curity/idsvr:6.5.0 curity.azurecr.io/curity/idsvr:6.5.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.5.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.5.0-centos7 curity.azurecr.io/curity/idsvr:6.5.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.5.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.5.0-buster-slim curity.azurecr.io/curity/idsvr:6.5.0-slim"
elif [ "${VERSION}" = "6.6.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.6.0-ubuntu curity.azurecr.io/curity/idsvr:6.6.0 curity.azurecr.io/curity/idsvr:6.6.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.6.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.6.0-centos7 curity.azurecr.io/curity/idsvr:6.6.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.6.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.6.0-buster-slim curity.azurecr.io/curity/idsvr:6.6.0-slim"
elif [ "${VERSION}" = "6.7.2" ]; then
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.7.0-ubuntu curity.azurecr.io/curity/idsvr:6.7.0 curity.azurecr.io/curity/idsvr:6.7.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.7.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.7.0-centos8 curity.azurecr.io/curity/idsvr:6.7.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.7.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.7.0-buster-slim curity.azurecr.io/curity/idsvr:6.7.0-slim"
fi

build_image "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18.04" "${VERSION}/ubuntu/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18" "curity.azurecr.io/curity/idsvr:${VERSION}" $EXTRA_TAGS_UBUNTU
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-${CENTOS_VERSION}" "${VERSION}/centos/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-centos" $EXTRA_TAGS_CENTOS
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-buster" "${VERSION}/buster/Dockerfile" $EXTRA_TAGS_BUSTER
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-buster-slim" "${VERSION}/buster-slim/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-slim" $EXTRA_TAGS_BUSTER_SLIM