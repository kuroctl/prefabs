# SteamCMD de Kuro (ADR-0048) : `runtime-base` + SteamCMD dans /opt/steamcmd. Sert aux étapes
# `steamcmd` des prefabs (conteneur d'installation) et d'image d'exécution aux jeux Steam Linux.
#
# SteamCMD se met à jour lui-même dans son dossier à chaque lancement : /opt/steamcmd appartient à
# 1000:1000, et ne s'écrit que dans le conteneur d'installation (racine inscriptible). Un service
# qui s'exécute avec cette image a une racine en lecture seule et ne lance pas SteamCMD.
# amd64 seulement : SteamCMD n'existe pas pour ARM.
ARG BASE=kuro/runtime-base:local
FROM ${BASE}

ENV STEAMCMDDIR=/opt/steamcmd

USER 0:0
# L'amorce de Valve n'a pas d'empreinte publiée : téléchargée en HTTPS depuis son CDN, puis mise à
# jour par SteamCMD lui-même (qui vérifie ses paquets). Le premier lancement la met à jour dans
# l'image, pour qu'une installation ne commence pas par là.
RUN set -eux; \
    mkdir -p "$STEAMCMDDIR"; \
    curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        | tar -xzf - -C "$STEAMCMDDIR"; \
    chown -R 1000:1000 "$STEAMCMDDIR"
USER 1000:1000
RUN set -eux; \
    "$STEAMCMDDIR/steamcmd.sh" +quit || "$STEAMCMDDIR/steamcmd.sh" +quit; \
    # Bibliothèque Steam des serveurs (`steamclient.so`), au chemin où ils la cherchent.
    mkdir -p "$HOME/.steam"; \
    ln -sfn "$STEAMCMDDIR/linux64" "$HOME/.steam/sdk64"; \
    ln -sfn "$STEAMCMDDIR/linux32" "$HOME/.steam/sdk32"; \
    rm -rf "$HOME/Steam/logs" "$HOME/Steam/appcache" "$STEAMCMDDIR/logs"

LABEL org.opencontainers.image.description="Kuro SteamCMD runtime: runtime-base with SteamCMD in /opt/steamcmd"

WORKDIR /home/kuro
