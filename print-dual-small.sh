#! /bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/logging.sh" || { echo "Failed to load logging.sh"; exit 1; };
source "$SCRIPT_DIR/.env" || { logThis "Failed to load .env." "INFO"; };

set -o nounset

if [ -z "${1-}" ]; then
  echo "Usage: $0 NUMBER [NUMBER]"
  exit 1
fi

CHR1="${1:0:1}"
CHR1="${CHR1^}"
NUM1="$(printf "%07.0f" "${1:1}")"

CHR2="$CHR1"
NUM2="$NUM1"

if [ -n "${2-}" ]; then
  CHR2="${2:0:1}"
  CHR2="${CHR2^^}"
  NUM2="$(printf "%07.0f" "${2:1}")"
fi

PAT1="$QK_ARCHIVE_BASE/$CHR1/$NUM1/label/"
PAT2="$QK_ARCHIVE_BASE/$CHR1/$NUM1/label/"
IMG1="$PAT1/${NUM1}.png"
IMG2="$PAT2/${NUM2}.png"

if [ ! -f "$IMG1" ]; then
  logThis "Input file $IMG1 ($1) does not exist." "ERROR"
  exit 1
fi

if [ ! -f "$IMG2" ]; then
  logThis "Input file $IMG2 ($2) does not exist." "ERROR"
  exit 1
fi

TMPFILE="$(mktemp "/tmp/$0.XXXXXX.png")"

convert "$IMG1" "$IMG2" +append "$TMPFILE"

$QK_TIV_EXEC "$TMPFILE"

# Pipe input from /dev/tty so this can be used in a while loop (subshell)
echo "[P/s/c] Print and save, just Save or Cancel"
read -r -n 1 COMMAND < /dev/tty;
echo
if [ -n "$COMMAND" ]; then
  if [[ "$COMMAND" =~ ^(S|s)$ ]]; then
    cp "$TMPFILE" "$PAT1/${CHR1}-${NUM1}-${CHR2}-${NUM2}.png"
    mv "$TMPFILE" "$PAT2/${CHR1}-${NUM1}-${CHR2}-${NUM2}.png"
    echo "Saved to $PAT1/${CHR1}-${NUM1}-${CHR2}-${NUM2}.png and $PAT2/${CHR1}-${NUM1}-${CHR2}-${NUM2}.png"
    exit 0;
  elif [[ "$COMMAND" =~ ^(C|c)$ ]]; then
    rm "$TMPFILE"
    exit 0
  fi
fi

brother_ql --model QL-810W --printer tcp://brother-ql-810w.intern.hild1.no print -l 62 "$TMPFILE"
cp "$TMPFILE" "$PAT1/${CHR1}-${NUM1}-${CHR2}-${NUM2}.png"
mv "$TMPFILE" "$PAT2/${CHR1}-${NUM1}-${CHR2}-${NUM2}.png"
