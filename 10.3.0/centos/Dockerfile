#
# Copyright (C) 2020 Curity AB. All rights reserved.
#
# The contents of this file are the property of Curity AB.
# You may not copy or use this file, in either source code
# or executable form, except in compliance with terms
# set by Curity AB.
#
# For further information, please contact Curity AB.
#

FROM quay.io/centos/centos:stream9 AS openssl-builder

RUN yum clean all && \
	yum install -y perl-core

ENV OPENSSL_VERSION=3.0.17

RUN cd /tmp && curl -L https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz --output openssl.tar.gz && \
    curl -L https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz.sha256 --output openssl.tar.gz.sha256 && \
    echo $(cat openssl.tar.gz.sha256) openssl.tar.gz | sha256sum -c && \
    tar -xf openssl.tar.gz && \
    rm openssl.tar.gz

RUN cd /tmp/openssl-${OPENSSL_VERSION} && ./config --prefix=/build --release \
    no-ec2m no-idea no-mdc2 no-rc5 no-ssl no-dtls no-dtls1-method no-dtls1_2-method && \
    make && \
    chmod -R go+rX . && \
    make TESTS=-test_afalg test && \
    make install_sw install_ssldirs && \
    ln -s /build/lib64 /build/lib

FROM quay.io/centos/centos:stream9

LABEL maintainer="Curity AB <info@curity.se>"

ARG TARGETARCH

EXPOSE 8443
EXPOSE 6749
EXPOSE 4465
EXPOSE 4466

RUN yum update -y && yum clean all

RUN groupadd --system --gid 10000 idsvr && useradd --system --no-create-home --uid 10001 --gid 10000 idsvr

ENV IDSVR_HOME /opt/idsvr
ENV JAVA_HOME $IDSVR_HOME/lib/java/jre
ENV PATH $IDSVR_HOME/bin:$JAVA_HOME/bin:$PATH
WORKDIR $IDSVR_HOME

COPY --chown=10001:10000 idsvr-10.3.0-${TARGETARCH}/idsvr /opt/idsvr
COPY --chown=10001:10000 first-run /opt/idsvr/etc/first-run
COPY --from=openssl-builder /build/bin/openssl /bin/
COPY --from=openssl-builder /build/lib/libssl.so.3 /lib64/
COPY --from=openssl-builder /build/lib/libcrypto.so.3 /lib64/

USER 10001:10000

CMD ["idsvr"]
