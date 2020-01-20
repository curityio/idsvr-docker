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

FROM centos:centos7 AS openssl-builder

RUN yum clean all && \
	yum install -y perl-core curl && \
	yum groupinstall -y "Development tools"

ENV OPENSSL_VERSION=1.1.1d

RUN cd /tmp && curl https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz --output openssl.tar.gz && \
    curl https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz.sha256 --output openssl.tar.gz.sha256 && \
    echo $(cat openssl.tar.gz.sha256) openssl.tar.gz | sha256sum -c && \
    tar -xf openssl.tar.gz && \
    rm openssl.tar.gz

RUN cd /tmp/openssl-${OPENSSL_VERSION} && ./config --prefix=/build --release \
    no-idea no-mdc2 no-rc5 no-ssl no-dtls no-dtls1-method no-dtls1_2-method && \
    make && \
    chmod -R go+rX . && \
    make test && \
    make install_sw install_ssldirs

FROM centos:centos7

LABEL maintainer="Curity AB <info@curity.se>"

EXPOSE 8443
EXPOSE 6749
EXPOSE 4465

RUN yum install -y openssh-clients && yum clean all

ENV IDSVR_HOME /opt/idsvr
ENV JAVA_HOME $IDSVR_HOME/lib/java/jre
ENV PATH $IDSVR_HOME/bin:$JAVA_HOME/bin:$PATH
WORKDIR $IDSVR_HOME

COPY --from=openssl-builder /build/bin/openssl /bin/
COPY --from=openssl-builder /build/lib/lib*so* /usr/lib64/

COPY idsvr-4.5.3/idsvr /opt/idsvr
COPY first-run /opt/idsvr/etc/first-run
COPY crypto.so /opt/idsvr/lib/confd/lib/core/crypto/priv/lib

CMD ["idsvr"]
