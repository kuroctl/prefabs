# Image d'installation de Kuro (ADR-0048) : `runtime-base` + outils des étapes `script` (`git`,
# archives, `jq`). Lancée sans root, dans le conteneur d'installation du prefab.
ARG BASE=kuro/runtime-base:local
FROM ${BASE}

USER 0:0
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends git unzip zip xz-utils bzip2 jq wget rsync; \
    rm -rf /var/lib/apt/lists/*

LABEL org.opencontainers.image.description="Kuro installer: runtime-base with git, archive tools and jq"

USER 1000:1000
WORKDIR /home/kuro
