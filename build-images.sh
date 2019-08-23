#/bin/bash

mkdir -p ${VERSION}/ubuntu
mkdir -p ${VERSION}/centos
mkdir -p ${VERSION}/stretch
mkdir -p ${VERSION}/stretch-slim

cat Dockerfile-ubuntu.template | sed -e "s/{{VERSION}}/$VERSION/g" > ${VERSION}/ubuntu/Dockerfile
cat Dockerfile-centos.template | sed -e "s/{{VERSION}}/$VERSION/g" > ${VERSION}/centos/Dockerfile
cat Dockerfile-stretch.template | sed -e "s/{{VERSION}}/$VERSION/g" > ${VERSION}/stretch/Dockerfile
cat Dockerfile-stretch-slim.template | sed -e "s/{{VERSION}}/$VERSION/g" > ${VERSION}/stretch-slim/Dockerfile

docker build --no-cache -t curity/idsvr:latest -t curity/idsvr:${VERSION} -t curity/idsvr:${VERSION}-ubuntu -t curity/idsvr:${VERSION}-ubuntu18 -t curity/idsvr:${VERSION}-ubuntu18.04 -f ${VERSION}/ubuntu/Dockerfile .
docker build --no-cache -t curity/idsvr:${VERSION}-centos -t curity/idsvr:${VERSION}-centos7 -f ${VERSION}/centos/Dockerfile .
docker build --no-cache -t curity/idsvr:${VERSION}-stretch -f ${VERSION}/stretch/Dockerfile .
docker build --no-cache -t curity/idsvr:${VERSION}-stretch-slim -t curity/idsvr:${VERSION}-slim -f ${VERSION}/stretch-slim/Dockerfile .