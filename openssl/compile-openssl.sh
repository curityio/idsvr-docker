#!/bin/bash

# Script that runs inside OpenSSL build agent (Docker container) and compiles OpenSSL

set -e

./config \
	--prefix=/build \
	--release \
	no-ec2m no-idea no-mdc2 no-rc5 no-ssl no-dtls no-dtls1-method no-dtls1_2-method

make

chmod -R go+rX .

su myuser -c "make test"

make install_sw install_ssldirs
