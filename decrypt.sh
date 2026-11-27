#!/bin/sh
# Sblocca il repository: estrae payload.tar.gz.enc nella cartella corrente.
#
#   sh decrypt.sh
#
# Chiede la chiave se non è in REELSTUDIO2_KEY o ~/.reelstudio2.key. Se la chiave
# è sbagliata openssl lo dice e non lascia niente a metà.
set -eu
cd "$(dirname "$0")"

ls payload.part.* >/dev/null 2>&1 || { echo "mancano le parti payload.part.*: sei nella cartella giusta?"; exit 1; }

KEY=${REELSTUDIO2_KEY:-}
if [ -z "$KEY" ]; then
  if [ -f "$HOME/.reelstudio2.key" ]; then
    KEY=$(cat "$HOME/.reelstudio2.key")
  else
    printf 'chiave: '
    read -r KEY
  fi
fi
[ -n "$KEY" ] || { echo "chiave vuota"; exit 1; }
export KEY

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

cat payload.part.* >"$TMP/joined"
if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -pass env:KEY -in "$TMP/joined" -out "$TMP/payload.tar.gz" 2>"$TMP/err"; then
  echo "chiave sbagliata o file corrotto"
  sed 's/^/  /' "$TMP/err" 2>/dev/null | head -3
  exit 1
fi

tar -xzf "$TMP/payload.tar.gz" -C .
echo "sbloccato. Prossimo passo: sh scripts/install.sh, poi leggi docs/README.md"
