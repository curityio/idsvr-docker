#!/bin/bash

set -e

DATE=$(/bin/date +%Y%m%d)

DOCKER_CONTEXT=${VERSION}

if [ ! -d "${VERSION}" ]; then
  mkdir -p "${VERSION}/ubuntu"
  mkdir -p "${VERSION}/centos"
  mkdir -p "${VERSION}/stretch"
  mkdir -p "${VERSION}/stretch-slim"

  cp first-run "${VERSION}/first-run"

  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-ubuntu.template > "${VERSION}/ubuntu/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-centos.template > "${VERSION}/centos/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-stretch.template > "${VERSION}/stretch/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-stretch-slim.template > "${VERSION}/stretch-slim/Dockerfile"
  CACHE_CONTROL=--no-cache
  DOCKER_CONTEXT="."
  NEW_IMAGE=true
fi

build_image() {
  IMAGE=$1
  DOCKERFILE=$2
  CURRENT_PUBLISHED_IMAGE_ID=""

   if [[ -z "${NEW_IMAGE}" ]] ; then
      # Download the current published image and store its ID
      docker pull "${IMAGE}" ##
      CURRENT_PUBLISHED_IMAGE_ID=$(docker images --filter=reference="${IMAGE}" --format "{{.ID}}")
   fi

  # Build the image again (it should use cache if the base layer is the same)
  docker build ${CACHE_CONTROL} -t "${IMAGE}" -f "${DOCKERFILE}" "${DOCKER_CONTEXT}"

  # Compare the newly built image with the published one
  BUILT_IMAGE_ID=$(docker images --filter=reference="${IMAGE}" --format "{{.ID}}")
  if [[ "${BUILT_IMAGE_ID}" != "${CURRENT_PUBLISHED_IMAGE_ID}" ]]; then
    if [[ -n "${PUSH_IMAGES}" ]] ; then docker push "${IMAGE}"; fi

    # Update the extra tags
    docker tag "${IMAGE}" "${IMAGE}-${DATE}"
    if [[ -n "${PUSH_IMAGES}" ]] ; then docker push "${IMAGE}-${DATE}"; fi

    for TAG in "${@:3}"
    do
      docker tag "${IMAGE}" "${TAG}"
      if [[ -n "${PUSH_IMAGES}" ]] ; then docker push "${TAG}"; fi
    done

  fi
}

build_image "curity/idsvr:${VERSION}-ubuntu18.04" "${VERSION}/ubuntu/Dockerfile" "curity/idsvr:${VERSION}-ubuntu" "curity/idsvr:${VERSION}-ubuntu18" "curity/idsvr:${VERSION}"
build_image "curity/idsvr:${VERSION}-centos7" "${VERSION}/centos/Dockerfile" "curity/idsvr:${VERSION}-centos"
build_image "curity/idsvr:${VERSION}-stretch" "${VERSION}/stretch/Dockerfile"
build_image "curity/idsvr:${VERSION}-stretch-slim" "${VERSION}/stretch-slim/Dockerfile" "curity/idsvr:${VERSION}-slim"