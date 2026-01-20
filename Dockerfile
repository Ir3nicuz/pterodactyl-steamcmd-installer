# syntax=docker/dockerfile:1
# ^^^ This line must be the first in the script to activate the Heredoc-Feature.

# use debian 12 as basic image
FROM debian:bookworm-slim

# Initials
ARG ARG_BUILD_NUMBER=-1
ENV ENV_BUILD_NUMBER=${ARG_BUILD_NUMBER}
ENV DEBIAN_FRONTEND=noninteractive
ENV WINEARCH=win64
ENV WINEPREFIX=/home/container/.wine
ENV WINEDEBUG=-all
ENV WINEDLLOVERRIDES="winealsa.drv,winemmoe.drv=d"

# SteamCmd and Wings dependencies integration
RUN apt update && apt install -y \
    curl \
    ca-certificates \
    lib32gcc-s1 \
    lib32stdc++6 \
    tar \
    locales \
    libasound2 \
    libasound2-plugins \
    alsa-utils \
    && locale-gen en_US.UTF-8 && apt-get clean

# SteamCMD-Manifest donwload and place in /opt/steamcmd
RUN mkdir -p /opt/steamcmd \
    && curl -sSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /opt/steamcmd

# SteamCMD-Binaries donwload and dependency test
RUN /opt/steamcmd/steamcmd.sh +login anonymous +quit || true

# wine initialisation
RUN wineboot -u && wineserver -w

# Here-Doc definition of install script as steamcmd
#RUN cat << 'EOF' > /usr/local/bin/steamcmd
RUN <<'EOF' cat > /usr/local/bin/steamcmd
#!/bin/bash

# Text marker colors
REDERRORTAG='\e[31m[ERROR]\e[0m'
GREENSUCCESSTAG='\e[32m[SUCCESS]\e[0m'
YELLOWWARNINGTAG='\e[33m[WARNING]\e[0m'
BLUEINFOTAG='\e[34m[INFO]\e[0m'

# startup
sleep 1
echo -e "${BLUEINFOTAG} Starting steamcmd script (Build-Rev: ${ENV_BUILD_NUMBER}) ..."
set -e

# --- Validation ---
if [[ -z "${STEAMGAME_APPID}" ]]; then
    echo -e "${REDERRORTAG} Variable STEAMGAME_APPID not set!"
    exit 1
fi
if ! [[ "${STEAMGAME_APPID}" =~ ^[0-9]+$ ]]; then
    echo -e "${REDERRORTAG} Variable STEAMGAME_APPID '${STEAMGAME_APPID}' is not a valid id!"
    exit 1
fi
if [[ "${STEAMGAME_FORCEVERSION+defined}" != "defined" ]]; then
    echo -e "${REDERRORTAG} Variable STEAMGAME_FORCEVERSION not set!"
    exit 1
fi
echo -e "${GREENSUCCESSTAG} Variables validation done!"

# --- Build SteamCmd arguments
STEAM_CMD_ARGS="+force_install_dir /mnt/server +@sSteamCmdForcePlatformType windows +login anonymous +app_update ${STEAMGAME_APPID}"
if ! [[ -z "${STEAMGAME_FORCEVERSION}" ]]; then
    echo -e "${YELLOWWARNINGTAG} Using Game Server Beta Branch ${STEAMGAME_FORCEVERSION}"
    STEAM_CMD_ARGS="${STEAM_CMD_ARGS} -beta ${STEAMGAME_FORCEVERSION}"
fi
STEAM_CMD_ARGS="${STEAM_CMD_ARGS} -validate +quit"
echo -e "${BLUEINFOTAG} Build SteamCmd Args: ${STEAM_CMD_ARGS}"

# --- Installation ---
echo -e "${BLUEINFOTAG} Starting SteamCmd install/update of Steam Id ${STEAMGAME_APPID} ..."
/opt/steamcmd/steamcmd.sh ${STEAM_CMD_ARGS}

echo -e "${GREENSUCCESSTAG} SteamCmd install/update done!"
EOF

# install script execution 
RUN chmod +x /usr/local/bin/steamcmd

# installation script context directory
WORKDIR /mnt/server

# execution syntax
CMD ["/bin/bash"]
