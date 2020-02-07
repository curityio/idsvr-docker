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

FROM buildpack-deps:buster

LABEL maintainer="Curity AB <info@curity.se>"

EXPOSE 8443
EXPOSE 6749
EXPOSE 4465

RUN apt-get update && apt-get upgrade -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* 

ENV PAGER=more
ENV IDSVR_HOME /opt/idsvr
ENV JAVA_HOME $IDSVR_HOME/lib/java/jre
ENV PATH /usr/local/ssl/bin:$IDSVR_HOME/bin:$JAVA_HOME/bin:$PATH
WORKDIR $IDSVR_HOME

COPY idsvr-4.5.3/idsvr /opt/idsvr
COPY first-run /opt/idsvr/etc/first-run
COPY crypto.so /opt/idsvr/lib/confd/lib/core/crypto/priv/lib

CMD ["idsvr"]
