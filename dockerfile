FROM alpine:3.21 AS base

ARG TARGETARCH

RUN apk add --no-cache wget unzip

RUN case "${TARGETARCH:-amd64}" in \
        "arm64") \
            TSHOCK_ARCH="arm64" ;; \
        *) \
            TSHOCK_ARCH="x64" ;; \
    esac && \
    TSHOCKURL="https://github.com/Pryaxis/TShock/releases/download/v6.2.1/TShock-6.2.1-for-Terraria-1.4.5.8-linux-${TSHOCK_ARCH}-Release.zip" && \
    wget "$TSHOCKURL" -O /tshock.zip && \
    mkdir /tshock && \
    unzip /tshock.zip -d /tshock && \
    rm /tshock.zip && \
    tar -xf "/tshock/TShock-Beta-linux-${TSHOCK_ARCH}-Release.tar" -C /tshock && \
    rm "/tshock/TShock-Beta-linux-${TSHOCK_ARCH}-Release.tar"

FROM mcr.microsoft.com/dotnet/runtime:9.0-noble

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends libicu-dev && \
    rm -rf /var/lib/apt/lists/*

COPY --from=base /tshock/ /tshock/

RUN chmod +x /tshock/TShock.Server

RUN echo '#!/bin/bash\n/tshock/TShock.Server -configpath /data -worldselectpath /data/worlds -logpath /data/logs "$@"' > /tshock/start.sh && \
    chmod +x /tshock/start.sh

VOLUME ["/data"]
EXPOSE 7777
WORKDIR /tshock
ENTRYPOINT ["/bin/bash", "/tshock/start.sh"]

# docker build -t terraria-docker:latest .
# docker run -it -p 7777:7777 -v /home/$USER/terraria:/data --name terraria-docker terraria-docker:latest
