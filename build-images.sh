#!/bin/bash

set -e

DATE=$(/bin/date +%Y%m%d)

DOCKER_CONTEXT=${VERSION}

build_image() {
  IMAGE=$1
  DOCKERFILE=$2
  if [[ -f "${DOCKERFILE}" ]] ; then
    # Download the current published image and store its ID
    docker pull "${IMAGE}" || true
    CURRENT_PUBLISHED_IMAGE_ID=$(docker images --filter=reference="${IMAGE}" --format "{{.ID}}")

    # Build the image again (it should use cache if the base layer is the same)
    docker build -t "${IMAGE}" -f "${DOCKERFILE}" "${DOCKER_CONTEXT}"

    # Compare the newly built image with the published one
    BUILT_IMAGE_ID=$(docker images --filter=reference="${IMAGE}" --format "{{.ID}}")

    if [[ "${BUILT_IMAGE_ID}" != "${CURRENT_PUBLISHED_IMAGE_ID}" ]]; then
      # Update the extra tags
      docker tag "${IMAGE}" "${IMAGE}-${DATE}"

      #Run sanity tests if RUN_SANITY_CHECK is set
      MAJOR_VERSION=(${VERSION//./ }[0])
      if [[ -n "${RUN_SANITY_CHECK}" ]] && [[ ${MAJOR_VERSION} -ge 5 ]] ; then
        echo "Running Sanity tests on image: ${IMAGE}-${DATE}"
        ./../tests/sanity-tests.sh 1 curity-idsvr admin Password1 ${IMAGE}-${DATE};
      fi

      #Run bats test if RUN_BATS_TEST is set
      if [[ -n "${RUN_BATS_TEST}" ]] ; then
        echo "Running Bats tests on image: ${IMAGE}-${DATE}"
        export BATS_CURITY_IMAGE=${IMAGE}-${DATE}
        tests/bats/bin/bats tests
      fi

      if [[ -n "${PUSH_IMAGES}" ]] ; then docker push "${IMAGE}"; fi

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
    else
      echo "Skip pushing ${IMAGE} because it is unchanged"
    fi
  fi
}

if [ "${VERSION}" = "5.3.1" ]; then
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:5.3.0-ubuntu curity.azurecr.io/curity/idsvr:5.3.0 curity.azurecr.io/curity/idsvr:5.3.0-ubuntu18 curity.azurecr.io/curity/idsvr:5.3.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:5.3.0-centos7 curity.azurecr.io/curity/idsvr:5.3.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:5.3.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:5.3.0-buster-slim curity.azurecr.io/curity/idsvr:5.3.0-slim"
elif [ "${VERSION}" = "6.0.1" ]; then
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.0.0-ubuntu curity.azurecr.io/curity/idsvr:6.0.0 curity.azurecr.io/curity/idsvr:6.0.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.0.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.0.0-centos7 curity.azurecr.io/curity/idsvr:6.0.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.0.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.0.0-buster-slim curity.azurecr.io/curity/idsvr:6.0.0-slim"
elif [ "${VERSION}" = "6.2.2" ]; then
  EXTRA_TAGS_UBUNTU="curity.azurecr.io/curity/idsvr:6.2.0-ubuntu curity.azurecr.io/curity/idsvr:6.2.0 curity.azurecr.io/curity/idsvr:6.2.0-ubuntu18 curity.azurecr.io/curity/idsvr:6.2.0-ubuntu18.04"
  EXTRA_TAGS_CENTOS="curity.azurecr.io/curity/idsvr:6.2.0-centos7 curity.azurecr.io/curity/idsvr:6.2.0-centos"
  EXTRA_TAGS_BUSTER="curity.azurecr.io/curity/idsvr:6.2.0-buster"
  EXTRA_TAGS_BUSTER_SLIM="curity.azurecr.io/curity/idsvr:6.2.0-buster-slim curity.azurecr.io/curity/idsvr:6.2.0-slim"
fi

build_image "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18.04" "${VERSION}/ubuntu/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18" "curity.azurecr.io/curity/idsvr:${VERSION}" $EXTRA_TAGS_UBUNTU
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-centos7" "${VERSION}/centos/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-centos" $EXTRA_TAGS_CENTOS
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-buster" "${VERSION}/buster/Dockerfile" $EXTRA_TAGS_BUSTER
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-buster-slim" "${VERSION}/buster-slim/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-slim" $EXTRA_TAGS_BUSTER_SLIM