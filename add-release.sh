#!/bin/bash

if [ ! -d "${VERSION}" ]; then
  mkdir -p "${VERSION}/ubuntu"
  mkdir -p "${VERSION}/centos"
  mkdir -p "${VERSION}/rhel"  
  mkdir -p "${VERSION}/debian"
  mkdir -p "${VERSION}/debian-slim"

  cp first-run "${VERSION}/first-run"
  cp .dockerignore "${VERSION}/.dockerignore"

  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-ubuntu.template > "${VERSION}/ubuntu/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-centos.template > "${VERSION}/centos/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-rhel.template > "${VERSION}/rhel/Dockerfile"  
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-debian.template > "${VERSION}/debian/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-debian-slim.template > "${VERSION}/debian-slim/Dockerfile"
fi
