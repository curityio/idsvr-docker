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

FROM ubuntu:18.04

LABEL maintainer="Curity AB <info@curity.se>"

EXPOSE 8443
EXPOSE 6749
EXPOSE 4465
EXPOSE 4466

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y libssl1.1 openssl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* 

RUN useradd --system idsvr

ENV IDSVR_HOME /opt/idsvr
ENV JAVA_HOME $IDSVR_HOME/lib/java/jre
ENV PATH $IDSVR_HOME/bin:$JAVA_HOME/bin:$PATH
WORKDIR $IDSVR_HOME

COPY idsvr-6.2.1/idsvr /opt/idsvr
COPY first-run /opt/idsvr/etc/first-run

RUN find /opt/idsvr -type f -exec chmod a-w {} \; && \
    chmod -R o-rwx /opt/idsvr && \
    chown -R idsvr /opt/idsvr && \
    chgrp -R 0 /opt/idsvr && \
    chmod -R g+rX /opt/idsvr

USER idsvr:idsvr

CMD ["idsvr"]