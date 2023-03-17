#! /bin/bash

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/.env" 2>/dev/null || echo "Failed to load .env"; exit 1;

set -o errexit
set -o nounset
set -o xtrace

STORAGE_DIR="./01_Output"

trap ctrl_c INT

function ctrl_c() {
        echo "Cleaning up"
        rm -- *.png 2>/dev/null
}

mkdir -p "$STORAGE_DIR"

if [ $# -eq 0 ]; then
  NUM="$(zenity --entry --text "Number")"
  TEXT="$(zenity --entry --text "Text")"
fi

if [ $# -eq 1 ]; then
  NUM="$1"
  TEXT="$(zenity --entry --text "Text")"
fi

if [ $# -eq 2 ]; then
  NUM="$1"
  TEXT="$2"
fi
# shellcheck disable=SC2010
MIN="$(cd $STORAGE_DIR/; ls -- *.png | grep -P '\d\d\d\d\d\d\d.png' | sort -n -r | head -1 | cut -d. -f1)"
if [ -z "$MIN" ]; then
  MIN=0;
fi
NUMOK="$(echo "$NUM <= $MIN" | bc)"
if [ $NUMOK -eq 1 ]; then
  echo "Input number ($NUM) is lower or equal to the largest number in $STORAGE_DIR ($MIN)" 1>&2
  exit 1
fi
LONGNUM="$(printf "%07.0f" "$NUM")"

qrencode --output="${LONGNUM}-qr.png" --type=PNG --ignorecase -s 10 -m 0 "H#${LONGNUM}";

convert -background white -fill black -size 210x50 -pointsize 45 -font "Ubuntu-Mono" -gravity center label:"H#${LONGNUM}" -trim "${LONGNUM}-label-in.png"
convert "${LONGNUM}-label-in.png" -gravity center -extent "$(identify -format "210x%[h]" "${LONGNUM}-label-in.png")" "${LONGNUM}-label.png"


WIDTH="$(echo "${#TEXT}/6" | bc)"
WIDTH="$((WIDTH>30 ? WIDTH : 30))"
FS="$(echo "$TEXT" | fold -s --width "$WIDTH")"
convert -background white -fill black -gravity Center -font "Ubuntu-Mono" -size 420x210  label:"${FS//$'\n'/\\n}" "${LONGNUM}-text.png"

convert "${LONGNUM}-qr.png" "${LONGNUM}-text.png" +append "${LONGNUM}-qr-text.png"
convert "${LONGNUM}-qr-text.png" "${LONGNUM}-label.png" -smush 5 "${LONGNUM}.png"

ristretto "${LONGNUM}.png" &
VIEWER_PID="$!"
# Must sleep because it takes a second before we can find the window,
# could in teory loop instead
sleep 1
# ristretto's title/name includes the filename
VIEWER=$(xdotool search --onlyvisible --name "${LONGNUM}.png");
# we must unmaximize (not minimize) before we move and resize
wmctrl -ir "$VIEWER" -b remove,maximized_vert,maximized_horz
xdotool windowmove "$VIEWER" 1920 550
xdotool windowsize "$VIEWER" 1000 500
if wait "$VIEWER_PID"; then
  #brother_ql --model QL-810W --printer tcp://brother-ql-810w.intern.hild1.no print -l 62red --red out.png
  brother_ql --model QL-810W --printer tcp://brother-ql-810w.intern.hild1.no print -l 62 "${LONGNUM}.png";
  echo "Movin all files to $STORAGE_DIR/"
  mv -- ./*.png "$STORAGE_DIR/";
else
  ctrl_c
fi
