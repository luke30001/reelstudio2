#!/bin/sh
# Richiude tutto in payload.tar.gz.enc. Da rilanciare dopo ogni modifica.
#
#   sh encrypt.sh
#
# La chiave si legge da REELSTUDIO2_KEY oppure da ~/.reelstudio2.key e non
# finisce mai nel repository.
set -eu
cd "$(dirname "$0")"

KEY=${REELSTUDIO2_KEY:-}
if [ -z "$KEY" ]; then
  [ -f "$HOME/.reelstudio2.key" ] || { echo "manca la chiave: CREA ~/.reelstudio2.key o esporta REELSTUDIO2_KEY"; exit 1; }
  KEY=$(cat "$HOME/.reelstudio2.key")
fi
export KEY

ITEMS="agent-skill bin config custom-styles docs extracted legacy-install scripts versions current install.json package.json update.json"
REDUCIBLES=
for i in $ITEMS; do [ -e "$i" ] && REDUCIBLES="$REDUCIBLES $i"; done

echo "impacchetto…"
rm -f payload.tar.gz.enc
tar -czf - --exclude .git $REDUCIBLES | openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -pass env:KEY -out payload.tar.gz.enc

# GitHub rifiuta i file oltre 100 MB: si spezza in parti da 80.
rm -f payload.part.*
split -b 80m payload.tar.gz.enc payload.part.
rm -f payload.tar.gz.enc
parts=$(ls payload.part.* | wc -l | tr -d ' ')
echo "scritte $parts parti, $(du -ch payload.part.* | tail -1 | cut -f1) in totale"
shasum -a 256 payload.part.* | awk '{print substr($1,1,16) "  " $2}'
