#! /bin/bash
if [ $# -ne 1 ]; then
  echo "Usage: $0 <start-num>"
  exit 1
fi

START_NUM="$1"
END_NUM="$(echo "$START_NUM + 15" | bc)"
FILES=()
for NUM in `seq -f "%07.0f" $START_NUM $END_NUM`; do
  if [ -z $FIRST ]; then FIRST=$NUM fi;
  LAST=$NUM;
  FILES+=("out-${NUM}.png")
  qrencode --output="out-${NUM}.png" --type=PNG --ignorecase -s 30 -m 0 "H#$NUM"; 
  convert "out-${NUM}.png" -pointsize 130 -font "Ubuntu-Mono" -gravity center label:"H#$NUM" -trim -smush 20 "out-${NUM}.png"
done;
montage $FILES -density 600 -tile 4x4 -geometry +30+30 $FIRST-$LAST-out.png;
ristretto $FIRST-$LAST-out.png
#brother_ql --model QL-810W --printer tcp://brother-ql-810w.intern.hild1.no print -l 62red --red out.png.png
mkdir "$FIRST-$LAST"
mv *.png "$FIRST-$LAST/"
