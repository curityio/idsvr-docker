#!/bin/bash

if [ ! -d "${VERSION}" ]; then
  mkdir -p "${VERSION}/ubuntu"
  mkdir -p "${VERSION}/centos"
  mkdir -p "${VERSION}/buster"
  mkdir -p "${VERSION}/buster-slim"

  cp first-run "${VERSION}/first-run"
  cp -r crypto_so_src "${VERSION}"
  cp .dockerignore "${VERSION}/.dockerignore"

  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-ubuntu.template > "${VERSION}/ubuntu/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-centos.template > "${VERSION}/centos/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-buster.template > "${VERSION}/buster/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-buster-slim.template > "${VERSION}/buster-slim/Dockerfile"
fi