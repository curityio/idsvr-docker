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
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.0-ubuntu curity.azurecr.io/curity/idsvr:5.0 curity.azurecr.io/curity/idsvr:5.0-ubuntu18 curity.azurecr.io/curity/idsvr:5.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.0-centos7 curity.azurecr.io/curity/idsvr:5.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.0-buster-slim curity.azurecr.io/curity/idsvr:5.0-slim"
elif [ "${VERSION}" = "5.1.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.1-ubuntu curity.azurecr.io/curity/idsvr:5.1 curity.azurecr.io/curity/idsvr:5.1-ubuntu18 curity.azurecr.io/curity/idsvr:5.1-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.1-centos7 curity.azurecr.io/curity/idsvr:5.1-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.1-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.1-buster-slim curity.azurecr.io/curity/idsvr:5.1-slim"
elif [ "${VERSION}" = "5.2.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.2-ubuntu curity.azurecr.io/curity/idsvr:5.2 curity.azurecr.io/curity/idsvr:5.2-ubuntu18 curity.azurecr.io/curity/idsvr:5.2-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.2-centos7 curity.azurecr.io/curity/idsvr:5.2-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.2-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.2-buster-slim curity.azurecr.io/curity/idsvr:5.2-slim"
elif [ "${VERSION}" = "5.3.5" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.3-ubuntu curity.azurecr.io/curity/idsvr:5.3 curity.azurecr.io/curity/idsvr:5.3-ubuntu18 curity.azurecr.io/curity/idsvr:5.3-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.3-centos7 curity.azurecr.io/curity/idsvr:5.3-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.3-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.3-buster-slim curity.azurecr.io/curity/idsvr:5.3-slim"
elif [ "${VERSION}" = "5.4.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.4-ubuntu curity.azurecr.io/curity/idsvr:5.4 curity.azurecr.io/curity/idsvr:5.4-ubuntu18 curity.azurecr.io/curity/idsvr:5.4-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.4-centos7 curity.azurecr.io/curity/idsvr:5.4-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.4-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.4-buster-slim curity.azurecr.io/curity/idsvr:5.4-slim"
elif [ "${VERSION}" = "6.0.5" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.0-ubuntu curity.azurecr.io/curity/idsvr:6.0 curity.azurecr.io/curity/idsvr:6.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.0-centos7 curity.azurecr.io/curity/idsvr:6.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.0-buster-slim curity.azurecr.io/curity/idsvr:6.0-slim"
elif [ "${VERSION}" = "6.1.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.1-ubuntu curity.azurecr.io/curity/idsvr:6.1 curity.azurecr.io/curity/idsvr:6.1-ubuntu18 curity.azurecr.io/curity/idsvr:6.1-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.1-centos7 curity.azurecr.io/curity/idsvr:6.1-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.1-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.1-buster-slim curity.azurecr.io/curity/idsvr:6.1-slim"
elif [ "${VERSION}" = "6.2.6" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.2-ubuntu curity.azurecr.io/curity/idsvr:6.2 curity.azurecr.io/curity/idsvr:6.2-ubuntu18 curity.azurecr.io/curity/idsvr:6.2-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.2-centos7 curity.azurecr.io/curity/idsvr:6.2-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.2-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.2-buster-slim curity.azurecr.io/curity/idsvr:6.2-slim"
elif [ "${VERSION}" = "6.3.5" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.3-ubuntu curity.azurecr.io/curity/idsvr:6.3 curity.azurecr.io/curity/idsvr:6.3-ubuntu18 curity.azurecr.io/curity/idsvr:6.3-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.3-centos7 curity.azurecr.io/curity/idsvr:6.3-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.3-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.3-buster-slim curity.azurecr.io/curity/idsvr:6.3-slim"
elif [ "${VERSION}" = "6.4.7" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.4-ubuntu curity.azurecr.io/curity/idsvr:6.4 curity.azurecr.io/curity/idsvr:6.4-ubuntu18 curity.azurecr.io/curity/idsvr:6.4-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.4-centos7 curity.azurecr.io/curity/idsvr:6.4-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.4-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.4-buster-slim curity.azurecr.io/curity/idsvr:6.4-slim"
elif [ "${VERSION}" = "6.5.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.5-ubuntu curity.azurecr.io/curity/idsvr:6.5 curity.azurecr.io/curity/idsvr:6.5-ubuntu18 curity.azurecr.io/curity/idsvr:6.5-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.5-centos7 curity.azurecr.io/curity/idsvr:6.5-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.5-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.5-buster-slim curity.azurecr.io/curity/idsvr:6.5-slim"
elif [ "${VERSION}" = "6.6.4" ]; then
  CENTOS_VERSION="centos7"
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.6-ubuntu curity.azurecr.io/curity/idsvr:6.6 curity.azurecr.io/curity/idsvr:6.6-ubuntu18 curity.azurecr.io/curity/idsvr:6.6-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.6-centos7 curity.azurecr.io/curity/idsvr:6.6-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.6-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.6-buster-slim curity.azurecr.io/curity/idsvr:6.6-slim"
elif [ "${VERSION}" = "6.7.3" ]; then
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.7-ubuntu curity.azurecr.io/curity/idsvr:6.7 curity.azurecr.io/curity/idsvr:6.7-ubuntu18 curity.azurecr.io/curity/idsvr:6.7-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.7-centos8 curity.azurecr.io/curity/idsvr:6.7-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.7-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.7-buster-slim curity.azurecr.io/curity/idsvr:6.7-slim"
elif [ "${VERSION}" = "6.8.1" ]; then
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.8-ubuntu curity.azurecr.io/curity/idsvr:6.8 curity.azurecr.io/curity/idsvr:6.8-ubuntu18 curity.azurecr.io/curity/idsvr:6.8-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.8-centos8 curity.azurecr.io/curity/idsvr:6.8-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.8-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.8-buster-slim curity.azurecr.io/curity/idsvr:6.8-slim"
fi

if [[ "$VERSION" == *.0 ]]; then
  BRANCH_VERSION=${VERSION%??}
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-ubuntu curity.azurecr.io/curity/idsvr:${BRANCH_VERSION} curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-ubuntu18 curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-centos8 curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-buster-slim curity.azurecr.io/curity/idsvr:${BRANCH_VERSION}-slim"
fi

build_image "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18.04" "${VERSION}/ubuntu/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18" "curity.azurecr.io/curity/idsvr:${VERSION}" $EXTRA_TAGS_UBUNTU
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-${CENTOS_VERSION}" "${VERSION}/centos/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-centos" $EXTRA_TAGS_CENTOS
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-buster" "${VERSION}/buster/Dockerfile" $EXTRA_TAGS_BUSTER
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-buster-slim" "${VERSION}/buster-slim/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-slim" $EXTRA_TAGS_BUSTER_SLIM