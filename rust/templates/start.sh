#!/bin/bash
# Lancement de Rust, copié sur le volume à l'installation.
#
# Rust n'enregistre le monde ni sur SIGINT ni sur SIGTERM : seulement par la commande `quit` (ou
# `server.save`), et sa console Linux ne lit pas l'entrée standard. À l'arrêt, ce script envoie
# donc `quit` par WebRCON (port interne au conteneur), puis attend la fin du serveur.
#
# - Le serveur tourne dans sa propre session (`setsid`) : `tini -g` relaie le signal d'arrêt au
#   groupe de ce script seulement, sans quoi Rust s'arrêterait avant d'avoir reçu `quit`.
# - WebRCON est un WebSocket : une poignée de main HTTP puis une trame texte, écrites avec
#   `/dev/tcp` de bash, sans outil de plus dans l'image.
# - Si WebRCON ne répond pas, le serveur reçoit SIGINT (arrêt sans enregistrement, comme avant).
# - Après `quit`, Rust se termine lui-même par SIGKILL (code 137) une fois le monde enregistré ; le
#   daemon ignore le code de sortie d'un arrêt qu'il a demandé.
set -euo pipefail

# webrcon <commande> : envoie une commande à WebRCON (RCON_PORT, RCON_PASSWORD).
webrcon() {
  local payload line
  payload=$(printf '{"Identifier":1,"Message":"%s","Name":"Kuro"}' "$1")
  exec 3<>"/dev/tcp/127.0.0.1/$RCON_PORT" || return 1
  printf 'GET /%s HTTP/1.1\r\nHost: 127.0.0.1:%s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: a3Vyby1rdXJvLWt1cm8tMQ==\r\nSec-WebSocket-Version: 13\r\n\r\n' \
    "$RCON_PASSWORD" "$RCON_PORT" >&3
  read -r -t 5 line <&3 || return 1
  case "$line" in *" 101 "*) ;; *) exec 3>&-; return 1 ;; esac
  while read -r -t 5 line <&3 && [ "$line" != $'\r' ]; do :; done
  # Trame texte unique, masquée par une clé nulle (masque obligatoire côté client, < 126 octets).
  printf "\\x81\\x$(printf %02x $((128 + ${#payload})))\\x00\\x00\\x00\\x00%s" "$payload" >&3
  sleep 1
  exec 3>&-
}

stop() {
  echo "kuro: stopping Rust through WebRCON (quit saves the world)"
  webrcon quit || { echo "kuro: WebRCON unavailable, sending SIGINT"; kill -INT "$pid" 2> /dev/null || true; }
}

cd /data/server
setsid ./RustDedicated "$@" &
pid=$!
trap stop INT TERM
# `wait` rend la main à l'arrivée d'un signal (code 130) : attendre la fin réelle du serveur, puis
# rendre son propre code de sortie (bash garde celui d'un enfant terminé).
while kill -0 "$pid" 2> /dev/null; do
  wait "$pid" || true
done
status=0
wait "$pid" || status=$?
exit "$status"
