# Docker-related Files and Info

[![Quality](https://img.shields.io/badge/quality-production-green)](https://curity.io/resources/code-examples/status/)
[![Availability](https://img.shields.io/badge/availability-binary-blue)](https://curity.io/resources/code-examples/status/)

This repository contains Dockerfiles and other resources that can be used to create Docker images of the [Curity Identity Server](https://curity.io). 

# Usage

* Download the linux release from the [Curity Developer portal](https://developer.curity.io/downloads)
* Extract the release in the `<VERSION>` directory of this project
* Run the command `VERSION=X.X.X ./build-images.sh $VERSION`

This will build the images using the Dockerfile(s) of the specific version locally.

# Adding a new version

In order to add a new version, run the following `VERSION=X.X.X ./add-release.sh`

# Image updates 

Since the base OS of the images can regularly be patched, the script `update-images.sh` is run every day to make sure that the images contain the latest security fixes. 

The script downloads the releases from Curity's release API, pulls the latest base OS images and rebuilds all the versions. If there is a change in the OS, the docker cache won't be used and the new images will be pushed to Docker hub.
  
So, the tag of the form `<version>-<os>` always contains the latest, while the tag `<version>-<os>-<date>` is the image that was built that specific date (which is never updated).

# Building a single image

* Download the linux release from the [Curity Developer portal](https://developer.curity.io/downloads)
* Extract the release in the `VERSION` directory of this project
* Run the command `docker build -t <image_tag> -f <VERSION>/<DISTRO>/Dockerfile <VERSION>`  

# Customizing the image

The Curity Identity Server is a Java based product and can run in many docker setups.\
The default docker image runs as a low privilege `10001` user account (`idsvr`).\
Customers can update this user account and apply their own image policy when required.

## Kubernetes Non Root Check

You may need to deploy the docker image and also use the Kubernetes `runAsNonRoot` security context setting:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: curity
    image: custom_idsvr:latest
```

If so, you will need to configure a numeric user ID.\
Do so by removing the default user and adding a numeric user and group.\
Then change file ownership to that user, which will inherit existing permissions.

```dockerfile
FROM curity.azurecr.io/curity/idsvr:latest
USER root

RUN deluser idsvr && \
    groupadd --system --gid 10000 idsvr && \
    useradd  --system --gid idsvr --uid 10001 --shell /bin/bash --create-home idsvr && \
    chown -R 10001 /opt/idsvr
USER 10001
```

> [!IMPORTANT]
> Images after version 9.0.0 already use the user `10001` instead of `idsvr` which means the `runAsNonRoot: true` securityContext is allowed by default  

## Custom image based on the provided images

If you need to install extra tools, you can do so by overlaying our image. 
In some cases, operation can only run with the root user. In that case it is advisable to switch to the root user, perform the operation that requires more permissions and then switch back to the user of the image

```dockerfile
USER root 
...
RUN apt-get install -y curl
...
USER 10001:1000

```
Also copying resources in the server files, i.e plugins can be done like so:
```dockerfile
COPY --chown=10001:10000 custom-plugin.jar /opt/idsvr/usr/share/plugins/custom-plugin-group/
```

> [!NOTE]
> For images before version 9.0.0 use `USER idsvr:idsvr`


# Contributing

Pull requests are welcome. To do so, just fork this repo, and submit a pull request. 

# License

The software running in the Docker containers produced by the Dockerfiles maintained in this repository is licensed by Curity AB and others. The Docker-related files and resources maintained in this respository are licensed under the [Apache 2 license](LICENSE).

# More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.

Copyright (C) 2019 Curity AB.
