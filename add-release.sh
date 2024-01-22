#!/bin/bash

if [ ! -d "${VERSION}" ]; then
  mkdir -p "${VERSION}/ubuntu"
  mkdir -p "${VERSION}/centos"
  mkdir -p "${VERSION}/rhel"  
  mkdir -p "${VERSION}/bookworm"
  mkdir -p "${VERSION}/bookworm-slim"

  cp first-run "${VERSION}/first-run"
  cp .dockerignore "${VERSION}/.dockerignore"

  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-ubuntu.template > "${VERSION}/ubuntu/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-centos.template > "${VERSION}/centos/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-rhel.template > "${VERSION}/rhel/Dockerfile"  
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-bookworm.template > "${VERSION}/bookworm/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" Dockerfile-bookworm-slim.template > "${VERSION}/bookworm-slim/Dockerfile"
fi
