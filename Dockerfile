FROM debian:stretch

# Create user meteor who will run all entrypoint instructions
RUN useradd meteor -G staff -m -s /bin/bash
WORKDIR /home/meteor

# Install git, curl
RUN apt-get update && \
   apt-get install -y git curl build-essential bzip2 gnupg libcap2-bin python && \
   (curl https://deb.nodesource.com/setup_8.x | bash) && \
   apt-get install -y nodejs jq && \
   apt-get clean && \
   rm -Rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN npm install -g semver


ARG RELEASE=latest
# ENV RELEASE $RELEASE

ARG CURL_OPTS
ENV CURL_OPTS $CURL_OPTS

# Install build
COPY build.sh /usr/bin/build.sh
RUN chmod +x /usr/bin/build.sh

# Install entrypoint
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

# Add known_hosts file
COPY known_hosts .ssh/known_hosts

RUN chown -R meteor:meteor .ssh /usr/bin/entrypoint.sh /usr/bin/build.sh

USER meteor

RUN curl ${CURL_OPTS} -o /tmp/meteor.sh https://install.meteor.com?release=${RELEASE}

RUN sh /tmp/meteor.sh
RUN rm /tmp/meteor.sh

USER root

EXPOSE 3000

CMD []
