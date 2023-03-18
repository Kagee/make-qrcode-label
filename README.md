# make-qrcode-label
Small wrapper scripts i use to generate, validate and print QR codes on a Brother QL-810W. Examples are printed on DK-22212 (62mm x 15,2m, "endless") label paper, and the printer will cut between each print.

## generate-qr-from-ods.sh
Will read from Openoffice ODS (se `example.ods`) and run `qr-with-text.sh` on lines, ignoring those already in `01_Output`

## qr-with-text.sh
Takes a number (ID) and text as input. Generates QR code with label.

![Image example of output from qr-with-text.sh](.github/qr-with-text.sh-example.jpg)

## make-qr-matrix.sh
Generates a matrix of QR codes.

![Image example of output from make-qr-matrix.sh](.github/make-qr-matrix.sh-example.jpg)

## ods2csv
Converts a ODS to CSV. Supports multiple sheets.

Made because all other tools sucked.
