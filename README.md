# Docker-related Files and Info

This repository contains Dockerfiles and other resources that can be used to create Docker images of the [Curity Identity Server](https://curity.io). 

# Usage

* Download the linux release from the (Curity Developer portal)[https://developer.curity.io/downloads]
* Extract the release in the `<VERSION>` directory of this project
* Run the command `VERSION=X.X.X ./build-images.sh $VERSION`

This will build the images using the Dockerfile(s) of the specific version locally.

# Adding a new version

In order to add a new version, run the following ```VERSION=X.X.X ./add-release.sh```

# Image updates 

Since the base OS of the images can regularly be patched, the script ```update-images.sh``` is run every day to make sure that the images contain the latest security fixes. 

The script downloads the releases from Curity's release API, pulls the latest base OS images and rebuilds all the versions. If there is a change in the OS, the docker cache won't be used and the new images will be pushed to Docker hub.
  
So, the tag of the form `<version>-<os>` always contains the latest, while the tag `<version>-<os>-<date>` is the image that was built that specific date (which is never updated).

# Building a single image

* Download the linux release from the (Curity Developer portal)[https://developer.curity.io/downloads]
* Extract the release in the `VERSION` directory of this project
* Run the command `docker build -t <image_tag> -f <VERSION>/<DISTRO>/Dockerfile <VERSION>`  

# Contributing

Pull requests are welcome. To do so, just fork this repo, and submit a pull request. 

# License

The software running in the Docker containers produced by the Dockerfiles maintained in this repository is licensed by Curity AB and others. The Docker-related files and resources maintained in this respository are licensed under the [Apache 2 license](LICENSE).

# More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.

Copyright (C) 2019 Curity AB.
