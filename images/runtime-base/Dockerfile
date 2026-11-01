# Image d'exécution de base de Kuro (ADR-0048) : Debian 13, bibliothèques courantes des serveurs de
# jeu, `tini` en point d'entrée, utilisateur `kuro` (1000:1000). Aucun jeu : il est installé dans
# le volume du serveur par le prefab.
#
# Contrat de la version majeure 1 : Debian 13 (GE-Proton 11 exige glibc 2.38, Debian 12 a la 2.36),
# uid 1000, `tini -g --` seul point d'entrée, aucun chemin de données imposé, rien n'est écrit hors
# du volume et des `writable` du prefab.
FROM docker.io/library/debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4

ARG TARGETARCH

# Bibliothèques 32 bits (SteamCMD, serveurs Source et Unity anciens) : amd64 seulement.
RUN set -eux; \
    if [ "$TARGETARCH" = "amd64" ]; then dpkg --add-architecture i386; fi; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl tzdata locales tini procps iproute2 gettext-base \
        libstdc++6 libssl3t64 libatomic1 libcurl4t64 libicu76 libtbb12 libfontconfig1 \
        libsdl2-2.0-0 libncurses6 zlib1g; \
    if [ "$TARGETARCH" = "amd64" ]; then \
        apt-get install -y --no-install-recommends \
            lib32gcc-s1 lib32stdc++6 lib32z1 libc6:i386 libsdl2-2.0-0:i386 \
            libcurl4t64:i386 libncurses6:i386; \
    fi; \
    sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd --gid 1000 kuro; \
    useradd --uid 1000 --gid 1000 --create-home --home-dir /home/kuro --shell /bin/bash kuro

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    USER=kuro \
    HOME=/home/kuro

LABEL org.opencontainers.image.source="https://github.com/kuroctl/prefabs" \
      org.opencontainers.image.description="Kuro base runtime: Debian 13, common game server libraries, tini, non-root user 1000" \
      org.opencontainers.image.licenses="0BSD" \
      io.kuroctl.contract="1"

USER 1000:1000
WORKDIR /home/kuro
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["bash"]
