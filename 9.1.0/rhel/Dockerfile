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

FROM registry.access.redhat.com/ubi8/ubi

LABEL maintainer="Curity AB <info@curity.se>"

EXPOSE 8443
EXPOSE 6749
EXPOSE 4465
EXPOSE 4466

RUN groupadd --system --gid 10000 idsvr && useradd --system --no-create-home --uid 10001 --gid 10000 idsvr

ENV IDSVR_HOME /opt/idsvr
ENV JAVA_HOME $IDSVR_HOME/lib/java/jre
ENV PATH $IDSVR_HOME/bin:$JAVA_HOME/bin:$PATH
WORKDIR $IDSVR_HOME

COPY --chown=10001:10000 idsvr-9.1.0/idsvr /opt/idsvr
COPY --chown=10001:10000 first-run /opt/idsvr/etc/first-run

USER 10001:10000

CMD ["idsvr"]
