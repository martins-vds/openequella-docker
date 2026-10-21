# Stage 1: Build & Automated Unattended Installation
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Install openEQUELLA system dependencies
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    imagemagick \
    ffmpeg \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp-install

# Fetch stable installer from openEQUELLA GitHub releases
# Note: Swap out the version tag dynamically depending on your build target
RUN curl -L -o equella-installer.zip https://github.com \
    && unzip equella-installer.zip \
    && cd equella-installer-*

# Execute the headless, silent install by piping default configuration responses directly to stdin
# This answers questions like install path, database engine choice, memory, etc.
RUN printf "/opt/openequella\n/usr/bin/convert\n/usr/bin/ffmpeg\n$JAVA_HOME\n3\n" | java -jar enterprise-install.jar

# Stage 2: Clean and Lean Runtime Image
FROM ubuntu:22.04

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:${PATH}"

RUN apt-get update && apt-get install -y \
    openjdk-8-jre-headless \
    imagemagick \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Bring over the fully configured server asset tree from builder layer
COPY --from=builder /opt/openequella /opt/openequella

WORKDIR /opt/openequella/manager

EXPOSE 8080 3000

# Execute server startup foreground loop script
CMD ["./equellaserver", "start"]
