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

FROM debian:bookworm-slim

LABEL maintainer="Curity AB <info@curity.se>"

ARG TARGETARCH

EXPOSE 8443
EXPOSE 6749
EXPOSE 4465
EXPOSE 4466

RUN apt-get update && apt-get upgrade -y && \
	apt-get install -y openssl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* 

RUN groupadd --system --gid 10000 idsvr && useradd --system --no-create-home --uid 10001 --gid 10000 idsvr

ENV IDSVR_HOME /opt/idsvr
ENV JAVA_HOME $IDSVR_HOME/lib/java/jre
ENV PATH $IDSVR_HOME/bin:$JAVA_HOME/bin:$PATH
WORKDIR $IDSVR_HOME

COPY --chown=10001:10000 idsvr-11.0.1-${TARGETARCH}/idsvr /opt/idsvr
COPY --chown=10001:10000 first-run /opt/idsvr/etc/first-run

RUN chmod -R +w /opt/idsvr/var/.plugins/

USER 10001:10000

CMD ["idsvr"]
