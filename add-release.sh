#!/bin/bash

if [ ! -d "${VERSION}" ]; then
  mkdir -p "${VERSION}/ubuntu"
  mkdir -p "${VERSION}/centos"
  mkdir -p "${VERSION}/stretch"
  mkdir -p "${VERSION}/stretch-slim"

  cp first-run "${VERSION}/first-run"

  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-ubuntu.template > "${VERSION}/ubuntu/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-centos.template > "${VERSION}/centos/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-stretch.template > "${VERSION}/stretch/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-stretch-slim.template > "${VERSION}/stretch-slim/Dockerfile"
fi