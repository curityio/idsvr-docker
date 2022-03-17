#!/bin/bash

set -e

D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE_BASE="curity.azurecr.io/curity/idsvr"

[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1;

# Pull base images once to avoid pull limit in dockerhub
docker pull ubuntu:18.04
docker pull quay.io/centos/centos:stream8
docker pull buildpack-deps:buster
docker pull debian:buster-slim

while IFS= read -r VERSION
do
if ! [[ "$VERSION" < "7.0.0" ]]; then
  export
  VERSION=${VERSION} "$D"/build-arm-images.sh
  VERSION=${VERSION} "$D"/create-multiplatform-images.sh
fi
done < <(find -- * -name "[0-9].[0-9].[0-9]" -type d | sort -r)

# Delete stopped containers and images
docker ps -a | awk '{ print $1,$2 }' | grep "${IMAGE_BASE}" | awk '{print $1 }' | xargs -I {} docker rm {}
docker images | awk '{ print $1,$3 }' | grep "${IMAGE_BASE}" | awk '{print $2 }' | xargs -I {} docker rmi {} --force
