#
# Copyright (C) 2019 Curity AB. All rights reserved.
#
# The contents of this file are the property of Curity AB.
# You may not copy or use this file, in either source code
# or executable form, except in compliance with terms
# set by Curity AB.
#
# For further information, please contact Curity AB.
#

FROM centos:centos7

LABEL maintainer="Curity AB <info@curity.se>"

EXPOSE 8443
EXPOSE 6749

RUN yum install -y openssl openssh-clients && yum clean all

ENV PAGER=more
ENV IDSVR_HOME /opt/idsvr
ENV JAVA_HOME $IDSVR_HOME/lib/java/jre
ENV PATH $IDSVR_HOME/bin:$JAVA_HOME/bin:$PATH
WORKDIR $IDSVR_HOME

COPY idsvr-4.4.0/idsvr /opt/idsvr
COPY first-run /opt/idsvr/etc/first-run

CMD ["idsvr"]
