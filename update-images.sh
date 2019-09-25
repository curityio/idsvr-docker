#!/bin/bash

set -e

[[ -z "$CLIENT_ID" ]] && echo "CLIENT_ID not set" &&  exit 1;
[[ -z "$CLIENT_SECRET" ]] && echo "CLIENT_SECRET not set" &&  exit 1;

TOKEN_ENDPOINT=https://login.curity.io/oauth/v2/token
RELEASE_API=https://releaseapi.curity.io/releases
SCOPE="release_download release_read"

LATEST_RELEASE=$(find -- * -maxdepth 0 -type d | sort -rh | head -n 1)

while IFS= read -r VERSION
do
  echo "Downloading version $VERSION";
  ACCESS_TOKEN=$(curl -d "grant_type=client_credentials&client_secret=${CLIENT_SECRET}&client_id=${CLIENT_ID}&scope=${SCOPE}" ${TOKEN_ENDPOINT} | jq -r '.access_token')

  if [[ "$ACCESS_TOKEN" == "null" ]]; then
    echo "Failed to get access token"
    exit 1
  fi

  RELEASE_FILENAME=idsvr-$VERSION-linux.tar.gz
  curl -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}/linux-release" > "${RELEASE_FILENAME}"

  RELEASE_HASH=$(curl -H "Authorization: Bearer ${ACCESS_TOKEN}" "${RELEASE_API}/${VERSION}" | jq -r '."linux-sha256-checksum"')
  echo "$RELEASE_HASH" "$RELEASE_FILENAME" | sha256sum -c

  tar -xf "$RELEASE_FILENAME"

  export VERSION=$VERSION
  ./build-images.sh
  docker images --format \"{{.Repository}}:{{.Tag}}\" | grep curity/idsvr:"${VERSION}" | xargs -n 1 docker push

done < <(find -- * -maxdepth 0 -type d)

docker tag curity/idsvr:"$LATEST_RELEASE" curity/idsvr:latest && docker push curity/idsvr:latest

