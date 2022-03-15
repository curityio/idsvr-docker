#!/bin/bash

set -e

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

done < <(find -- * -name "[0-9].[0-9].[0-9]" -type d | sort -r)

# Delete stopped containers and images
docker ps -a | awk '{ print $1,$2 }' | grep "curity.azurecr.io/curity/idsvr" | awk '{print $1 }' | xargs -I {} docker rm {}
docker images | awk '{ print $1,$3 }' | grep "curity.azurecr.io/curity/idsvr" | awk '{print $2 }' | xargs -I {} docker rmi {} --force