#!/bin/sh
# Sblocca il repository: rimette i file in chiaro partendo da payload.index e
# dai pezzi in payload/.
#
#   sh decrypt.sh
#
# Chiede la chiave se non è in REELSTUDIO2_KEY o ~/.reelstudio2.key. Ogni voce
# è verificata con SHA-256 prima di essere aperta: una parte corrotta si ferma
# lì, senza lasciare un albero a metà.
set -eu
cd "$(dirname "$0")"

[ -f payload.index ] || { echo "manca payload.index: sei nella cartella giusta?"; exit 1; }
[ -d payload ] || { echo "manca payload/: sei nella cartella giusta?"; exit 1; }

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

while IFS="$(printf '\t')" read -r item parts sha; do
  [ -n "$item" ] || continue
  salt=$(printf '%s' "$item" | shasum -a 256 | cut -c1-32)
  base="$TMP/$(printf '%s' "$item" | tr '/' '_')"
  i=1
  : >"$base.enc"
  while [ "$i" -le "$parts" ]; do
    n=$(printf '%03d' $((i - 1)))
    part="payload/$(printf '%s' "$item" | tr '/' '_').enc.p$n"
    [ -f "$part" ] || { echo "manca $part"; exit 1; }
    cat "$part" >>"$base.enc"
    i=$((i + 1))
  done
  got=$(shasum -a 256 "$base.enc" | cut -d' ' -f1)
  [ "$got" = "$sha" ] || { echo "parte corrotta per $item"; exit 1; }
  if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -nosalt -S "$salt" \
    -pass env:KEY -in "$base.enc" -out "$base.tar.gz" 2>"$TMP/err"; then
    echo "chiave sbagliata o parte corrotta ($item)"
    sed 's/^/  /' "$TMP/err" 2>/dev/null | head -3
    exit 1
  fi
  tar -xzf "$base.tar.gz" -C .
done <payload.index

echo "sbloccato. Prossimo passo: sh scripts/install.sh, poi leggi docs/README.md"
