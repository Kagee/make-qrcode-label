#! /bin/bash

if [ ! -f "$1" ]; then
  echo "Usage: $0 /path/to/archive.ods"
exit 1
fi
ODS="$1"

set -o errexit
set -o nounset
#set -o xtrace
STORAGE_DIR="./01_Output"

trap ctrl_c INT

function ctrl_c() {
        echo "Cleaning up"
        rm -- *.png 2>/dev/null
}

mkdir -p "$STORAGE_DIR"

# shellcheck disable=SC2010
MIN="$(cd $STORAGE_DIR/; ls -- *.png 2>/dev/null | grep -P '\d\d\d\d\d\d\d.png' | sort -n -r | head -1 | cut -d. -f1 | bc)"
if [ -z "$MIN" ]; then
  MIN=0;
fi
DATA="$(unoconv -f csv -e FilterOptions=9,34,76 --stdout "$ODS" | tail -n +2)"

echo "$DATA" | while read -r ROW; do
  ID="$(echo "$ROW" | cut -f 1)";
  NAME="$(echo "$ROW" | cut -f 2)";
  if [ "$ID" = "$NAME" ]; then
    echo "ID $ID has no name, stopping here." 1>&2;
    exit 0;
  fi;
  NUM="$(echo "$ID" | cut -d\# -f 2 | bc)"
  echo "ID $ID has name $NAME" 1>&2;
  if [ "$NUM" -gt "$MIN" ]; then
    ./qr-with-text.sh "$NUM" "$NAME"
  else
    echo "ID $ID er allerede printet"
  fi
done
