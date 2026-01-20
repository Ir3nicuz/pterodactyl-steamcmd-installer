# syntax=docker/dockerfile:1
# ^^^ Diese Zeile MUSS ganz oben stehen! Sie aktiviert das Heredoc-Feature.

# use debian 12 as basic image
FROM debian:bookworm-slim

# Initials
ARG ARG_BUILD_NUMBER=-1
ENV ENV_BUILD_NUMBER=${ARG_BUILD_NUMBER}
ENV DEBIAN_FRONTEND=noninteractive

# SteamCmd dependencies integration
RUN apt update && apt install -y \
    curl \
    ca-certificates \
    lib32gcc-s1 \
    lib32stdc++6 \
    tar \
    locales \
    && locale-gen en_US.UTF-8

# SteamCMD-Manifest donwload and place in /opt/steamcmd
RUN mkdir -p /opt/steamcmd \
    && curl -sSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /opt/steamcmd

# SteamCMD-Binaries donwload and dependency test
RUN /opt/steamcmd/steamcmd.sh +login anonymous +quit || true

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
sleep 3
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
if [[ -z "${STEAMGAME_USEEXPERIMENTAL}" ]]; then
    echo -e "${REDERRORTAG} Variable STEAMGAME_USEEXPERIMENTAL not set!"
    exit 1
fi
if ! [[ "${STEAMGAME_USEEXPERIMENTAL}" =~ ^[0-1]$ ]]; then
    echo -e "${REDERRORTAG} Variable STEAMGAME_USEEXPERIMENTAL '${STEAMGAME_USEEXPERIMENTAL}' must be 0 or 1!"
    exit 1
fi
echo -e "${GREENSUCCESSTAG} Variables validation done!"

STEAM_CMD_ARGS="+force_install_dir /mnt/server +@sSteamCmdForcePlatformType windows +login anonymous +app_update ${STEAMGAME_APPID}"
if [[ "${STEAMGAME_USEEXPERIMENTAL}" == "1" ]]; then
    STEAM_CMD_ARGS="${STEAM_CMD_ARGS} -beta latest_experimental"
fi
STEAM_CMD_ARGS="${STEAM_CMD_ARGS} validate +quit"
echo -e "${GREENSUCCESSTAG} Build SteamCmd Args done: ${STEAM_CMD_ARGS}"

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
