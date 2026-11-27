# ReelStudio2 — repo sigillato

Tutto il contenuto (programma, stili, istruzioni estratte, chiavi, documentazione)
sta in `payload.tar.gz.enc`, cifrato con AES-256 e una chiave che **non** è qui
dentro. Senza la chiave il repository è illeggibile.

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
si richiude con `sh encrypt.sh` e si fa commit del solo `payload.tar.gz.enc`.

## Se la chiave gira

Chiunque abbia la chiave legge tutto, comprese le chiavi API in `config/keys.env`.
Non è un vault: è una busta sigillata. Se serve ruotare, cambia la chiave,
rilancia `sh encrypt.sh`, e considera compromesse le chiavi API dentro.

## Cosa c'è dentro

Un fork rinominato di ReelFactory 1.9.32 con voce diretta su ElevenLabs, stili
propri, pubblicazione Instagram diretta e le istruzioni degli agenti estratte.
I dettagli stanno in `docs/README.md`, che si legge dopo aver sbloccato.
