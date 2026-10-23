FROM alpine:3.21 AS base

ARG TARGETARCH

# Local TShock build from the hcross fork (TShock 6.2.1 / Terraria 1.4.5.8
# + NPC sync heartbeat fix, branch fix/npc-invisible-heartbeat).
# The tar ships pre-extracted release layout (same as the official
# TShock-Beta-linux-x64-Release.tar): built with
#   dotnet publish TShockLauncher/TShockLauncher.csproj -c Release
#   tar -cf release/TShock-Beta-linux-x64-Release.tar -C .../publish .
COPY release/TShock-Beta-linux-x64-Release.tar /tshock-release.tar

RUN apk add --no-cache tar && \
    mkdir /tshock && \
    tar -xf /tshock-release.tar -C /tshock && \
    rm /tshock-release.tar

FROM mcr.microsoft.com/dotnet/runtime:9.0-noble

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends libicu-dev && \
    rm -rf /var/lib/apt/lists/*

COPY --from=base /tshock/ /tshock/

# Diagnostic probe (invisible-NPC investigation, 2026-10-23): passive TSAPI plugin
# that logs NPC spawns, outgoing NpcUpdate/NpcHealth/Teleport packets and, every
# two seconds, each player's position plus nearby active NPCs, to /data/logs/syncprobe.log.
COPY probe/SyncProbe.dll /tshock/ServerPlugins/

RUN chmod +x /tshock/TShock.Server

RUN echo '#!/bin/bash\n/tshock/TShock.Server -configpath /data -worldselectpath /data/worlds -logpath /data/logs "$@"' > /tshock/start.sh && \
    chmod +x /tshock/start.sh

VOLUME ["/data"]
EXPOSE 7777
WORKDIR /tshock
ENTRYPOINT ["/bin/bash", "/tshock/start.sh"]

# docker build -t terraria-docker:latest .
# docker run -it -p 7777:7777 -v /home/$USER/terraria:/data --name terraria-docker terraria-docker:latest
