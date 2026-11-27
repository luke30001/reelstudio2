# ReelStudio2 — repo sigillato

Tutto il contenuto (programma, stili, istruzioni estratte, chiavi, documentazione)
sta in `payload/`, cifrato con AES-256 e una chiave che **non** è qui dentro.
Senza la chiave il repository è illeggibile.

`payload/` ha un pezzo cifrato per voce e `payload.index` li elenca. Non è un
blob unico apposta: un push porta solo le voci cambiate, non 220 MB ogni volta.

## Sbloccare

Serve la chiave, che si riceve fuori da GitHub. Poi:

```sh
git clone git@github.com:luke30001/reelstudio2.git
cd reelstudio2
cp /percorso/della/chiave ~/.reelstudio2.key    # oppure export REELSTUDIO2_KEY=...
chmod 600 ~/.reelstudio2.key
sh decrypt.sh
```

`decrypt.sh` verifica la chiave, estrae tutto e ti lascia il repository normale:
da lì valgono `sh scripts/install.sh` e `docs/README.md`.

## Aggiornare

```sh
git pull
sh decrypt.sh          # sovrascrive col contenuto nuovo
```

Gli aggiornamenti del programma si fanno con `sh scripts/sync-upstream.sh`, poi
si richiude con `sh encrypt.sh` e si fa commit di `payload/` e `payload.index`.

## Se la chiave gira

Chiunque abbia la chiave legge tutto, comprese le chiavi API in `config/keys.env`.
Non è un vault: è una busta sigillata. Se serve ruotare, cambia la chiave,
rilancia `sh encrypt.sh`, e considera compromesse le chiavi API dentro.

## Cosa c'è dentro

Un programma per reel 9:16 con voce diretta su ElevenLabs, stili propri,
presentatori generati qui, pubblicazione Instagram diretta e istruzioni degli
agenti congelate sul disco. Gira senza server (`REELSTUDIO2_STANDALONE=1`). La
provenienza del motore sta in `NOTICE`; il resto in `docs/README.md`, che si
legge dopo aver sbloccato.
