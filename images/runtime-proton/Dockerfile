# Proton GE de Kuro (ADR-0048) : `runtime-steamcmd` + une version de Proton GE dans /opt/proton,
# lisible par tous et sur le PATH (`proton run …`). Une image par version de Proton GE utilisée
# (`runtime-proton-ge10`, `runtime-proton-ge11`) : un jeu dépend d'une version précise (ADR-0032).
#
# Le préfixe Wine (`STEAM_COMPAT_DATA_PATH`), `HOME` et la bibliothèque Steam relayée
# (`STEAM_COMPAT_CLIENT_INSTALL_PATH`) sont sur le volume : réglés par le prefab.
# amd64 seulement.
ARG BASE=kuro/runtime-steamcmd:local
FROM ${BASE}

# Version de Proton GE : tag de la release GitHub et nom de son archive (sans `.tar.gz`), dont le
# nom change selon les versions (`GE-Proton10-34`, `GE-Proton11-11-x86_64`).
ARG GE_PROTON_TAG
ARG GE_PROTON_ASSET

USER 0:0
RUN set -eux; \
    test -n "$GE_PROTON_TAG"; \
    test -n "$GE_PROTON_ASSET"; \
    apt-get update; \
    # `libvulkan1` : le script `proton` charge le chargeur Vulkan au démarrage, même sans affichage.
    apt-get install -y --no-install-recommends \
        python3 libvulkan1 libfreetype6 libgnutls30t64 libdbus-1-3 libpulse0 libasound2t64 dbus; \
    rm -rf /var/lib/apt/lists/*; \
    # Identifiant de machine attendu par Wine (racine en lecture seule à l'exécution).
    dbus-uuidgen --ensure=/etc/machine-id; \
    cd /tmp; \
    url="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$GE_PROTON_TAG"; \
    curl -fsSLO "$url/$GE_PROTON_ASSET.tar.gz"; \
    curl -fsSLO "$url/$GE_PROTON_ASSET.sha512sum"; \
    # Somme publiée avec la release : vérifie l'archive téléchargée.
    sha512sum -c "$GE_PROTON_ASSET.sha512sum"; \
    mkdir -p /opt/proton; \
    tar -xzf "$GE_PROTON_ASSET.tar.gz" -C /opt/proton --strip-components=1; \
    rm -f "$GE_PROTON_ASSET.tar.gz" "$GE_PROTON_ASSET.sha512sum"; \
    chmod -R a+rX /opt/proton; \
    test -x /opt/proton/proton

ENV PATH=/opt/proton:$PATH \
    GE_PROTON=$GE_PROTON_TAG

LABEL org.opencontainers.image.description="Kuro Proton runtime: runtime-steamcmd with GE-Proton in /opt/proton"

USER 1000:1000
WORKDIR /home/kuro
