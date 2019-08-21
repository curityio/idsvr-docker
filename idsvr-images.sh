#/bin/bash

VERSION=$1
RELEASE_FILENAME=idsvr-${VERSION}-linux.tar.gz


if [ $# -ne 1 ] 
then
	echo error version is not set. Usage: version.sh VERSION
	exit 255;
fi

tar -xvf ${RELEASE_FILENAME} && rm ${RELEASE_FILENAME}

mkdir -p ${VERSION}/ubuntu
mkdir -p ${VERSION}/centos
mkdir -p ${VERSION}/strech
mkdir -p ${VERSION}/strech-slim

cat Dockerfile-ubuntu.template | sed -e "s/{{VERSION}}/$VERSION/g" > ${VERSION}/ubuntu/Dockerfile
cat Dockerfile-centos.template | sed -e "s/{{VERSION}}/$VERSION/g" > ${VERSION}/centos/Dockerfile
cat Dockerfile-stretch.template | sed -e "s/{{VERSION}}/$VERSION/g" > ${VERSION}/strech/Dockerfile
cat Dockerfile-stretch-slim.template | sed -e "s/{{VERSION}}/$VERSION/g" > ${VERSION}/strech-slim/Dockerfile

docker build -t curity/idsvr:latest -t curity/idsvr:${VERSION} -t curity/idsvr:${VERSION}-ubuntu -t curity/idsvr:${VERSION}-ubuntu18 -t curity/idsvr:${VERSION}-ubuntu18.04 -f ${VERSION}/ubuntu/Dockerfile .
docker build -t curity/idsvr:${VERSION}-centos -t curity/idsvr:${VERSION}-centos7 -f ${VERSION}/centos/Dockerfile .
docker build -t curity/idsvr:${VERSION}-stretch -f ${VERSION}/strech/Dockerfile .
docker build -t curity/idsvr:${VERSION}-stretch-slim -t curity/idsvr:${VERSION}-slim -f ${VERSION}/stretch-slim/Dockerfile .

docker images --format "{{.Repository}}:{{.Tag}}" | grep curity/idsvr:${VERSION} | xargs -n 1 docker push
docker push curity/idsvr:latest