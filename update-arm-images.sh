#!/bin/bash

set -e

DATE=$(/bin/date +%Y%m%d)

[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1;

LATEST_RELEASE=$(find -- * -maxdepth 0 -type d | sort -rh | head -n 1)

# Pull base images once to avoid pull limit in dockerhub
docker pull ubuntu:18.04

while IFS= read -r VERSION
do
if ! [[ "$VERSION" < "7.0.0" ]]; then
  export VERSION=${VERSION}
  ./build-arm-images.sh
  ./create-ubuntu-multiplatform-image.sh
fi
done < <(find -- * -name "[0-9].[0-9].[0-9]" -type d | sort -r)