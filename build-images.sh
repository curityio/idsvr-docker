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
    fi
  fi
}

build_image "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18.04" "${VERSION}/ubuntu/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu" "curity.azurecr.io/curity/idsvr:${VERSION}-ubuntu18" "curity.azurecr.io/curity/idsvr:${VERSION}"
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-centos7" "${VERSION}/centos/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-centos"
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-stretch" "${VERSION}/stretch/Dockerfile"
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-stretch-slim" "${VERSION}/stretch-slim/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-slim"
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-buster" "${VERSION}/buster/Dockerfile"
build_image "curity.azurecr.io/curity/idsvr:${VERSION}-buster-slim" "${VERSION}/buster-slim/Dockerfile" "curity.azurecr.io/curity/idsvr:${VERSION}-slim"