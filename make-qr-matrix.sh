#! /bin/bash

trap ctrl_c INT

function ctrl_c() {
        echo "Cleaning up"
        rm -- *.png 2>/dev/null
}

if [ $# -ne 1 ]; then
  echo "Usage: $0 <start-num>"
  exit 1
fi

START_NUM="$1"
END_NUM="$(echo "$START_NUM + 15" | bc)"
FILES=()
# generate 16 zerofilled numbers from $START_NUM
for NUM in $(seq -f "%07.0f" "$START_NUM" "$END_NUM"); do
  if [ -z "$FIRST" ]; then FIRST="$NUM"; fi;
  LAST=$NUM;
  FILES+=("out-${NUM}.png")
  qrencode --output="out-${NUM}.png" --type=PNG --ignorecase -s 30 -m 0 "H#$NUM";
  convert "out-${NUM}.png" -pointsize 130 -font "Ubuntu-Mono" -gravity center label:"H#$NUM" -trim -smush 20 "out-${NUM}.png"
done;
echo "Made image from H#$FIRST to H#$LAST"
# Make a 4x4 (16) image montage
montage "${FILES[@]}" -density 600 -tile 4x4 -geometry +30+30 "$FIRST-$LAST-out.png";
ristretto "$FIRST-$LAST-out.png" &
VIEWER_PID="$!"
# Must sleep because it takes a second before we can find the window,
# could in teory loop instead
sleep 1
# ristretto's title/name includes the filename
VIEWER=$(xdotool search --onlyvisible --name "$FIRST-$LAST-out.png");
# we must unmaximize (not minimize) before we move and resize
wmctrl -ir "$VIEWER" -b remove,maximized_vert,maximized_horz
xdotool windowmove "$VIEWER" 1920 550
xdotool windowsize "$VIEWER" 500 500
if wait "$VIEWER_PID"; then
  #brother_ql --model QL-810W --printer tcp://brother-ql-810w.intern.hild1.no print -l 62red --red out.png
  brother_ql --model QL-810W --printer tcp://brother-ql-810w.intern.hild1.no print -l 62 "$FIRST-$LAST-out.png";
  echo "Movin all files to $FIRST-$LAST/"
  mkdir "$FIRST-$LAST";
  mv -- ./*.png "$FIRST-$LAST/";
else
  ctrl_c
fi
