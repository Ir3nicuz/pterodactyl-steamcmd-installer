# use debian 12 as basic image
FROM debian:bookworm-slim

# Install silently with standard options
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
RUN cat << 'EOF' > /usr/local/bin/steamcmd \
#!/bin/bash \
# Text marker colors \
REDERRORTAG='\e[31m[ERROR]\e[0m' \
GREENSUCCESSTAG='\e[32m[SUCCESS]\e[0m' \
YELLOWWARNINGTAG='\e[33m[WARNING]\e[0m' \
BLUEINFOTAG='\e[34m[INFO]\e[0m' \
 \
echo -e "${BLUEINFOTAG} Starting steamcmd script ..." \
 \
# activate abort on error \
set -e \
 \
# --- Validation --- \
if [[ -z "${STEAMGAME_APPID}" ]]; then \
    echo -e "${REDERRORTAG} Variable STEAMGAME_APPID not set!" \
    exit 1 \
fi \
if ! [[ "${STEAMGAME_APPID}" =~ ^[0-9]+$ ]]; then \
    echo -e "${REDERRORTAG} Variable STEAMGAME_APPID '${STEAMGAME_APPID}' is not a valid id!" \
    exit 1 \
fi \
if [[ -z "${STEAMGAME_USEEXPERIMENTAL}" ]]; then \
    echo -e "${REDERRORTAG} Variable STEAMGAME_USEEXPERIMENTAL not set!" \
    exit 1 \
fi \
if ! [[ "${STEAMGAME_USEEXPERIMENTAL}" =~ ^[0-1]$ ]]; then \
    echo -e "${REDERRORTAG} Variable STEAMGAME_USEEXPERIMENTAL '${STEAMGAME_USEEXPERIMENTAL}' must be 0 or 1!" \
    exit 1 \
fi \
STEAMGAME_USEEXPERIMENTAL_COMMAND='' \
if [[ "${STEAMGAME_USEEXPERIMENTAL}" == "1" ]]; then \
    STEAMGAME_USEEXPERIMENTAL_COMMAND='-beta latest_experimental' \
fi \
 \
echo -e "${GREENSUCCESSTAG} Variables validation done!" \
echo -e "${BLUEINFOTAG} Starting SteamCmd install/update of Steam Id ${STEAMGAME_APPID} ..." \
 \
# --- Installation --- \
/opt/steamcmd/steamcmd.sh \
    +force_install_dir /mnt/server \
    +@sSteamCmdForcePlatformType windows \
    +login anonymous \
    +app_update "${STEAMGAME_APPID}" ${STEAMGAME_USEEXPERIMENTAL_COMMAND} -validate \
    +quit \
echo -e "${GREENSUCCESSTAG} SteamCmd install/update done!" \
EOF

# install script execution 
RUN chmod +x /usr/local/bin/steamcmd

# installation script context directory
WORKDIR /mnt/server

# execution syntax
CMD ["/bin/bash"]
