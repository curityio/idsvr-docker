#!/bin/bash

set -e

DATE=$(/bin/date +%Y%m%d)

[[ -z "${CLIENT_ID}" ]] && echo "CLIENT_ID not set" >&2 && exit 1;
[[ -z "${CLIENT_SECRET}" ]] && echo "CLIENT_SECRET not set" >&2 && exit 1;

LATEST_RELEASE=$(find -- * -maxdepth 0 -type d | sort -rh | head -n 1)

# Pull base images once to avoid pull limit in dockerhub
docker pull centos:centos7
docker pull quay.io/centos/centos:stream8
docker pull buildpack-deps:stretch
docker pull debian:stretch-slim
docker pull buildpack-deps:buster
docker pull debian:buster-slim
docker pull ubuntu:18.04

while IFS= read -r VERSION
do

  # build the images and push them. Latest pushed separately after the loop to avoid making each release :latest while running this script.
  export VERSION=${VERSION}
  ./build-images.sh
  docker images | awk '{ print $1,$3 }' | grep "curity.azurecr.io/curity/idsvr" | awk '{print $2 }' | xargs -I {} docker rmi {} --force

done < <(find -- * -name "[0-9].[0-9].[0-9]" -type d | sort -r)

## Push the latest tag if updated

# Download the current published latest
docker pull curity.azurecr.io/curity/idsvr:latest || true


CURRENT_LATEST_LAST_LAYER_ID=$(docker inspect curity.azurecr.io/curity/idsvr:latest | jq ".[0].RootFS.Layers[-1]")
LATEST_IMAGE_INSPECT=$(docker inspect "curity.azurecr.io/curity/idsvr:${LATEST_RELEASE}-ubuntu18.04")

if [[ $LATEST_IMAGE_INSPECT != *$CURRENT_LATEST_LAST_LAYER_ID* ]]; then
  if [[ -n "${PUSH_IMAGES}" ]] ; then
    echo "Pushing image: curity.azurecr.io/curity/idsvr:latest"
    docker tag "curity.azurecr.io/curity/idsvr:${LATEST_RELEASE}-ubuntu18.04" curity.azurecr.io/curity/idsvr:latest && docker push curity.azurecr.io/curity/idsvr:latest;
  fi
fi

# Delete stopped containers and images
docker ps -a | awk '{ print $1,$2 }' | grep "curity.azurecr.io/curity/idsvr" | awk '{print $1 }' | xargs -I {} docker rm {}
docker rmi curity.azurecr.io/curity/idsvr:latest
docker images | awk '{ print $1,$3 }' | grep "curity.azurecr.io/curity/idsvr" | awk '{print $2 }' | xargs -I {} docker rmi {} --force