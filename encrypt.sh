#!/bin/sh
# Richiude il repo nei pezzi cifrati. Da rilanciare dopo ogni modifica.
#
#   sh encrypt.sh
#
# Un file per voce in cima al repo, non un blob unico: così un push porta solo
# i pezzi cambiati, invece di 219 MB ogni volta. Ogni voce è cifrata con la sua
# chiave derivata dal nome (PBKDF2, sale fisso = sha256 del nome), quindi lo
# stesso contenuto dà sempre gli stessi byte.
#
# La chiave si legge da REELSTUDIO2_KEY o ~/.reelstudio2.key e non finisce mai
# nel repository.
set -eu
cd "$(dirname "$0")"

KEY=${REELSTUDIO2_KEY:-}
if [ -z "$KEY" ]; then
  [ -f "$HOME/.reelstudio2.key" ] || { echo "manca la chiave: CREA ~/.reelstudio2.key o esporta REELSTUDIO2_KEY"; exit 1; }
  KEY=$(cat "$HOME/.reelstudio2.key")
fi
export KEY

ITEMS="agent-skill bin config custom-styles docs extracted legacy-install NOTICE LICENSE CONTRIBUTING.md scripts versions current install.json package.json update.json"
REDUCIBLES=
for i in $ITEMS; do [ -e "$i" ] && REDUCIBLES="$REDUCIBLES $i"; done

OUT=payload
TMP=payload.tmp
rm -rf "$TMP" "$OUT"
mkdir -p "$TMP"

# L'indice: nome, quante parti, sha256 del cifrato. Righe in ordine di estrazione.
: >"$TMP/index"

for item in $REDUCIBLES; do
  salt=$(printf '%s' "$item" | shasum -a 256 | cut -c1-32)
  base="$TMP/$(printf '%s' "$item" | tr '/' '_')"
  # -n: gzip senza nome né orario, così il risultato dipende solo dal contenuto.
  COPYFILE_DISABLE=1 tar -cf - --exclude .git "$item" 2>/dev/null |
    gzip -n -c |
    openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -nosalt -S "$salt" -pass env:KEY -out "$base.enc"
  parts=0
  split -a 3 -d -b 80m "$base.enc" "$base.enc.p"
  rm -f "$base.enc"
  for p in "$base.enc.p"*; do parts=$((parts + 1)); done
  sha=$(cat "$base.enc.p"* | shasum -a 256 | cut -d' ' -f1)
  printf '%s\t%s\t%s\n' "$item" "$parts" "$sha" >>"$TMP/index"
done

mkdir -p "$OUT"
mv "$TMP"/*.enc.p* "$OUT"/
mv "$TMP/index" payload.index
rmdir "$TMP"

# Le parti vecchie fuori indice se ne vanno.
for f in "$OUT"/*; do
  n=$(basename "$f")
  grep -q "$(printf '%s' "$n" | sed 's/\.enc\.p.*//; s/_/\//g')" payload.index 2>/dev/null || rm -f "$f"
done

parts=$(ls "$OUT" | wc -l | tr -d ' ')
echo "scritti $parts pezzi, $(du -ch "$OUT" | tail -1 | cut -f1) in totale"
shasum -a 256 payload.index | awk '{print "indice " substr($1,1,16)}'
