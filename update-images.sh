#!/bin/bash

set -e

DATE=$(/bin/date +%Y%m%d)

[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1;

TOKEN_ENDPOINT=https://login.curity.io/oauth/v2/token
RELEASE_API=https://releaseapi.curity.io/releases
SCOPE="release_download release_read"

LATEST_RELEASE=$(find -- * -maxdepth 0 -type d | sort -rh | head -n 1)

# Pull base images to avoid using the cache for those
docker pull centos:centos7
docker pull buildpack-deps:stretch
docker pull debian:stretch-slim
docker pull buildpack-deps:buster
docker pull debian:buster-slim
docker pull ubuntu:18.04
docker pull curity.azurecr.io/curity/idsvr:latest

while IFS= read -r VERSION
do
  echo "Downloading version ${VERSION}";
  ACCESS_TOKEN=$(curl -s -S -d "grant_type=client_credentials&client_secret=${CLIENT_SECRET}&client_id=${CLIENT_ID}&scope=${SCOPE}" "${TOKEN_ENDPOINT}" | jq -r '.access_token')

  if [[ "${ACCESS_TOKEN}" == "null" ]]; then
    echo "Failed to get access token" >&2
    exit 1
  fi

  # Download the release from the release API
  RELEASE_FILENAME="idsvr-${VERSION}-linux.tar.gz"
  curl -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}/linux-release" > "${RELEASE_FILENAME}"

  # Verify hash of downloaded file
  RELEASE_HASH=$(curl -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}" | jq -r '."linux-sha256-checksum"')
  echo "${RELEASE_HASH}" "${RELEASE_FILENAME}" | sha256sum -c

  tar -xf "${RELEASE_FILENAME}" -C "${VERSION}"

  if jq -e -r '."'$VERSION'"' hotfixes.json > /dev/null; then
    # Applying hotfix for $VERSION
    HOTFIX_PATH=$(jq -e -r '."'$VERSION'".hotfix_path' hotfixes.json)

    curl -f -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}/${HOTFIX_PATH}/file" > "${HOTFIX_PATH}-${VERSION}.tgz"

    for original_file in $(jq -e -r '."'$VERSION'".original_files[]' hotfixes.json); do
      rm "${VERSION}/idsvr-${VERSION}/${original_file}"
    done

    tar -xf "${HOTFIX_PATH}-${VERSION}.tgz" --exclude='*.md' -C "${VERSION}/idsvr-${VERSION}"
  fi

  # build the images and push them. Latest pushed seperately after the loop to avoid making each release :latest while running this script.
  export VERSION=${VERSION}
  ./build-images.sh

done < <(find -- * -maxdepth 0 -type d)

## Push the latest tag if updated
CURRENT_LATEST_IMAGE_ID=$(docker images --filter=reference="curity.azurecr.io/curity/idsvr:latest-ubuntu18.04" --format "{{.ID}}")
LATEST_IMAGE_ID=$(docker images --filter=reference="curity.azurecr.io/curity/idsvr:${LATEST_RELEASE}-ubuntu18.04" --format "{{.ID}}")

if [[ "${LATEST_IMAGE_ID}" != "${CURRENT_LATEST_IMAGE_ID}" ]]; then
  if [[ -n "${PUSH_IMAGES}" ]] ; then
    echo "Pushing image: curity.azurecr.io/curity/idsvr:latest"
    docker tag "curity.azurecr.io/curity/idsvr:${LATEST_RELEASE}-ubuntu18.04" curity.azurecr.io/curity/idsvr:latest && docker push curity.azurecr.io/curity/idsvr:latest;
  fi
fi

# Clean up date tags
docker images --format \"\{\{.Repository\}\}:\{\{.Tag\}\}\" | grep "curity.azurecr.io/curity/idsvr:.*-${DATE}" | xargs -rn 1 docker rmi