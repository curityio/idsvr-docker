#!/bin/bash

set -e

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SUFFIX="${TARGET_ARCH:-}"
UNPACK_DIR="$D/$VERSION/idsvr-$VERSION$SUFFIX"
[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1

TOKEN_ENDPOINT=https://login.curity.io/oauth/v2/token
RELEASE_API=https://releaseapi.curity.io/releases
SCOPE="release_download release_read"

ACCESS_TOKEN=$(curl -f -s -S -d "grant_type=client_credentials&client_secret=${CLIENT_SECRET}&client_id=${CLIENT_ID}&scope=${SCOPE}" "${TOKEN_ENDPOINT}" | jq -r '.access_token')

if [[ "${ACCESS_TOKEN}" == "null" ]]; then
  echo "Failed to get access token" >&2
  exit 1
fi

RELEASE_HASH=$(curl -f -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}" | jq -r ".\"${ARTIFACT}-sha256-checksum\"")

# Download the release from the release API
RELEASE_FILENAME="idsvr-${VERSION}-${ARTIFACT}.tar.gz"
DOWNLOAD_RELEASE=
if [ -f "$RELEASE_FILENAME" ]; then
  echo "$RELEASE_FILENAME found"
  CALCULATED_RELEASE_HASH=$(openssl sha256 "${RELEASE_FILENAME}")
  if [[ $CALCULATED_RELEASE_HASH != *$RELEASE_HASH* ]]; then
    echo "$RELEASE_FILENAME hash is NOT OK"
    rm "$RELEASE_FILENAME"
  else
    echo "$RELEASE_FILENAME hash was verified, will skip download"
    DOWNLOAD_RELEASE=1
  fi
fi

if [ -z $DOWNLOAD_RELEASE ]; then
  echo "Downloading ${RELEASE_FILENAME}";
  curl -f -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}/${ARTIFACT}-release" > "${RELEASE_FILENAME}"
fi

# Verify hash of downloaded file
CALCULATED_RELEASE_HASH=$(openssl sha256 "${RELEASE_FILENAME}")
if [[ $CALCULATED_RELEASE_HASH != *$RELEASE_HASH* ]]; then
  echo "Release hash verification failed, expecting $RELEASE_HASH and got $CALCULATED_RELEASE_HASH for $RELEASE_FILENAME"
  exit 1
fi

mkdir -p "$UNPACK_DIR"
tar -xzf "${RELEASE_FILENAME}" -C "$UNPACK_DIR" --strip-components 1

if jq -e -r '."'$VERSION'"' hotfixes.json > /dev/null 2>&1; then
  # Applying hotfix for $VERSION
  HOTFIX_PATH=$(jq -e -r '."'$VERSION'".hotfix_path' hotfixes.json)

  curl -f -s -S -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}/${HOTFIX_PATH}/file" > "${HOTFIX_PATH}-${VERSION}.tgz"

  for original_file in $(jq -e -r '."'$VERSION'".original_files[]' hotfixes.json); do
    rm "${UNPACK_DIR}/${original_file}"
  done

  tar -xzf "${HOTFIX_PATH}-${VERSION}.tgz" --exclude='*.md' -C "$UNPACK_DIR"
fi
