# syntax=docker/dockerfile:1
FROM node:24.18.0-bookworm-slim AS node

FROM eclipse-temurin:21-jdk-noble AS source
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl git libtinfo6 python3 unzip \
    && rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/ /usr/local/
WORKDIR /src
RUN git init \
    && git remote add origin https://github.com/openequella/openEQUELLA.git \
    && git fetch --depth 1 origin eef854b1048eeb1b2686aeca1dd202751d5b9dfc \
    && git checkout --detach FETCH_HEAD \
    && test "$(node --version)" = "v$(cat .nvmrc)"
RUN --mount=type=cache,target=/root/.sbt \
    --mount=type=cache,target=/root/.ivy2 \
    --mount=type=cache,target=/root/.cache \
    cd graphql-client/scala && ./sbt -batch -J-Xmx2G publishLocal
RUN --mount=type=cache,target=/root/.sbt \
    --mount=type=cache,target=/root/.ivy2 \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/root/.npm \
    ./sbt -batch -J-Xmx4G installerZip

FROM eclipse-temurin:21-jdk-alpine AS base
RUN apk add --no-cache bash curl ffmpeg gcompat ghostscript imagemagick unzip \
    && adduser -D -s /bin/bash equella
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

FROM base AS installer
COPY --from=source /src/Installer/target/equella-installer-*.zip /tmp/installer.zip
COPY --from=source /src/docker/defaults.xml /defaults.xml
RUN unzip /tmp/installer.zip -d /tmp \
    && mv /tmp/equella-installer-* /equella-installer \
    && java -jar /equella-installer/enterprise-install.jar --unsupported /defaults.xml \
    && test -s /home/equella/equella/server/equella-server.jar \
    && test -s /home/equella/equella/manager/equellaserver-config.sh \
    && mkdir -p /home/equella/equella/filestore /home/equella/equella/freetext

FROM base AS runtime
COPY --from=installer --chown=equella:equella /home/equella/equella /home/equella/equella
COPY --from=source --chown=equella:equella /src/docker/learningedge-log4j.yaml /home/equella/equella/learningedge-config/
COPY --chmod=755 entrypoint.sh /usr/local/bin/openequella
WORKDIR /home/equella/equella/manager
USER equella
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/openequella"]
