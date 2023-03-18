#! /bin/bash

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.env" 2>/dev/null || echo "Failed to load .env"; exit 1;

echo "not using env vars"
exit 1
if [ -z "$1" ]; then
  echo "Usage: <number>"
exit 1
fi


set -o errexit
set -o nounset

STORAGE_DIR="./01_Output"
INPUT="$(printf "%07.0f" "$1").png"

trap ctrl_c INT

function ctrl_c() {
        echo "Cleaning up"
        rm -- *.png 2>/dev/null
}

if [ ! -f "$STORAGE_DIR/$INPUT" ]; then
  echo "Input file $STORAGE_DIR/$INPUT does not exist." 1>&2
  exit 1
fi

TMPFILE="$(mktemp "/tmp/$0.XXXXXX.png")"

convert "$STORAGE_DIR/$INPUT" "$STORAGE_DIR/$INPUT" +append "$TMPFILE"

brother_ql --model QL-810W --printer tcp://brother-ql-810w.intern.hild1.no print -l 62 "$TMPFILE"

rm "$TMPFILE"
