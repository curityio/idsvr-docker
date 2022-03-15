#!/bin/bash

set -e

[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1;

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

# Delete stopped containers and images
docker ps -a | awk '{ print $1,$2 }' | grep "curity.azurecr.io/curity/idsvr" | awk '{print $1 }' | xargs -I {} docker rm {}
docker images | awk '{ print $1,$3 }' | grep "curity.azurecr.io/curity/idsvr" | awk '{print $2 }' | xargs -I {} docker rmi {} --force