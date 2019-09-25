#!/bin/bash

if [ ! -d "${VERSION}" ]; then
  mkdir -p "${VERSION}/ubuntu"
  mkdir -p "${VERSION}/centos"
  mkdir -p "${VERSION}/stretch"
  mkdir -p "${VERSION}/stretch-slim"

  sed -e "s/{{VERSION}}/${VERSION}/g" < Dockerfile-ubuntu.template > "${VERSION}/ubuntu/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" < Dockerfile-centos.template > "${VERSION}/centos/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" < Dockerfile-stretch.template > "${VERSION}/stretch/Dockerfile"
  sed -e "s/{{VERSION}}/${VERSION}/g" < Dockerfile-stretch-slim.template > "${VERSION}/stretch-slim/Dockerfile"
fi

docker build --no-cache -t curity/idsvr:latest -t "curity/idsvr:${VERSION}" -t "curity/idsvr:${VERSION}-ubuntu" -t "curity/idsvr:${VERSION}-ubuntu18" -t "curity/idsvr:${VERSION}-ubuntu18.04" -f "${VERSION}/ubuntu/Dockerfile" .
docker build --no-cache -t "curity/idsvr:${VERSION}-centos" -t "curity/idsvr:${VERSION}-centos7" -f "${VERSION}/centos/Dockerfile" .
docker build --no-cache -t "curity/idsvr:${VERSION}-stretch" -f "${VERSION}/stretch/Dockerfile" .
docker build --no-cache -t "curity/idsvr:${VERSION}-stretch-slim" -t "curity/idsvr:${VERSION}-slim" -f "${VERSION}/stretch-slim/Dockerfile" .