# Docker-related Files and Info

This repository contains Dockerfiles and other resources that can be used to create Docker images of the [Curity Identity Server](https://curity.io). 

# Usage

* Download the linux release from the (Curity Developer portal)[https://developer.curity.io/downloads]
* Extract the release in the root directory of this project
* Run the command `export VERSION=X.X.X; ./build-images.sh <VERSION>`

This will unpack the release, create a version folder and copy the Dockerfiles inside it and then build the images and push them to docker hub.


# Contributing

Pull requests are welcome. To do so, just fork this repo, and submit a pull request. 

# License

The software running in the Docker containers produced by the Dockerfiles maintained in this repository is licensed by Curity AB. The Docker-related files and resources maintained in this respository are licensed under the [Apache 2 license](LICENSE>).

# More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.

Copyright (C) 2019 Curity AB.
