#! /bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/.env" || { echo "Failed to load .env" && exit 99; };
source "$SCRIPT_DIR/logging.sh" || { echo "Failed to load logging.sh"; exit 1; };

script_logging_level="DEBUG"

#set -o errexit
set -o nounset
#set -o xtrace

trap ctrl_c INT

TMP_DIR="$(mktemp -d -t "$(basename "$0").XXXXXXXXXX")"
logThis "TMP_DIR is $TMP_DIR" "INFO"

function ctrl_c() {
        echo "Cleaning up"
        rm -r "$TMP_DIR" 2>/dev/null
}

if [ -z "${QK_NUM-}" ]; then
  if [ $# -gt 0 ]; then
    QK_NUM="$1"
  else
    QK_NUM="$(zenity --entry --text "Serial number for label")"
  fi
fi

if [ -z "${QK_NUM-}" ]; then
  logThis "No serial number supplied" "ERROR"
  exit 1;
fi

if [ -z "${QK_TEXT-}" ]; then
  if [ $# -gt 1 ]; then
    QK_TEXT="$2"
  else
    QK_TEXT="$(zenity --entry --text "Text for label")"
  fi
fi

if [ -z "${QK_TEXT-}" ]; then
  logThis "No text supplied" "ERROR"
  exit 1;
fi
logThis "NUM is '$QK_NUM'" "INFO"
logThis "TEXT is '$QK_TEXT'" "INFO"

BASE_LETTER=${QK_NUM:0:1}
NUM="${QK_NUM:2}"
STORAGE_DIR="$QK_ARCHIVE_BASE/$BASE_LETTER/$NUM"

logThis "Storage dir is $STORAGE_DIR" "INFO"

mkdir -p "$STORAGE_DIR"

OUTPUTFILE="$STORAGE_DIR/$NUM.png"
if [ -f "$OUTPUTFILE" ]; then
  logThis "File already exsists: $OUTPUTFILE" "ERROR"
  exit 1;
fi
exit 100
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
  rm -r $TMP_DIR 2>/dev/null || true
else
  ctrl_c
fi
