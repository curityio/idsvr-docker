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

FROM amazonlinux:2023

LABEL maintainer="Curity AB <info@curity.se>"

ARG TARGETARCH

EXPOSE 8443
EXPOSE 6749
EXPOSE 4465
EXPOSE 4466

RUN yum update -y && yum clean all

ENV IDSVR_HOME /opt/idsvr
ENV JAVA_HOME $IDSVR_HOME/lib/java/jre
ENV PATH $IDSVR_HOME/bin:$JAVA_HOME/bin:$PATH
WORKDIR $IDSVR_HOME

COPY idsvr-10.0.2-${TARGETARCH}/idsvr /opt/idsvr
COPY first-run /opt/idsvr/etc/first-run

CMD ["idsvr"]
