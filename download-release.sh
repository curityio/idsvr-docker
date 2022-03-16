#!/bin/bash

set -e

[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1

TOKEN_ENDPOINT=https://login.curity.io/oauth/v2/token
RELEASE_API=https://releaseapi.curity.io/releases
SCOPE="release_download release_read"

echo "Downloading version ${VERSION}";
ACCESS_TOKEN=$(curl -f -s -S -d "grant_type=client_credentials&client_secret=${CLIENT_SECRET}&client_id=${CLIENT_ID}&scope=${SCOPE}" "${TOKEN_ENDPOINT}" | jq -r '.access_token')

if [[ "${ACCESS_TOKEN}" == "null" ]]; then
  echo "Failed to get access token" >&2
  exit 1
fi

# Download the release from the release API
RELEASE_FILENAME="idsvr-${VERSION}-${ARTIFACT}.tar.gz"
if [ ! -f $RELEASE_FILENAME ]; then
  curl -f -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}/${ARTIFACT}-release" > "${RELEASE_FILENAME}"
fi

# Verify hash of downloaded file
RELEASE_HASH=$(curl -f -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}" | jq -r ".\"${ARTIFACT}-sha256-checksum\"")
echo "${RELEASE_HASH}" "${RELEASE_FILENAME}" | sha256sum -c

tar -xf "${RELEASE_FILENAME}" -C "${VERSION}"

if jq -e -r '."'$VERSION'"' hotfixes.json > /dev/null 2>&1; then
  # Applying hotfix for $VERSION
  HOTFIX_PATH=$(jq -e -r '."'$VERSION'".hotfix_path' hotfixes.json)

  curl -f -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}/${HOTFIX_PATH}/file" > "${HOTFIX_PATH}-${VERSION}.tgz"

  for original_file in $(jq -e -r '."'$VERSION'".original_files[]' hotfixes.json); do
    rm "${VERSION}/idsvr-${VERSION}/${original_file}"
  done

  tar -xf "${HOTFIX_PATH}-${VERSION}.tgz" --exclude='*.md' -C "${VERSION}/idsvr-${VERSION}"
fi
