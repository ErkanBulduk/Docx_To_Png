#!/bin/bash
echo beginning loop
set -e

libreoffice="/c/Program Files/LibreOffice/program/soffice.exe"

while true
do
    if [ "$(find "$PWD/data/fileToConvert" -type f)" ]; then
        find "$PWD/data/fileToConvert" -type f \( -iname "*.docx" -o -iname "*.pdf" -o -iname "*.pptx" \) | while read FILE
        do 
            echo "Processing $FILE"
            EXT="${FILE##*.}"
            NAME="${FILE##*/}" 
            NAME_NO_EXT="${NAME%.*}"

            # Récupérer chemin relatif depuis fileToConvert
            REL_PATH="${FILE#$PWD/data/fileToConvert/}"
            REL_DIR="$(dirname "$REL_PATH")"
            PDF_OUTPUT_DIR="$PWD/data/pdf/$REL_DIR"

            mkdir -p "$PDF_OUTPUT_DIR"

            if [[ "$EXT" == "docx" || "$EXT" == "pptx" ]]
            then
                echo "$EXT found - converting $NAME_NO_EXT to PDF"
                "$libreoffice" --headless --convert-to pdf "$FILE" --outdir "$PDF_OUTPUT_DIR"
                echo "Conversion done for $NAME_NO_EXT"
                sleep 3
            elif [[ "$EXT" == "pdf" ]]
            then
                echo "PDF found - copying to $PDF_OUTPUT_DIR"
                cp "$FILE" "$PDF_OUTPUT_DIR"
            else
                echo "Unsupported file type: $EXT"
                continue
            fi

            # Archiver l’original
            echo "Archiving $FILE"
            mkdir -p "$PWD/data/archives/$REL_DIR"
            cp "$FILE" "$PWD/data/archives/$REL_DIR"

            # Supprimer l’original
            echo "Removing original $FILE"
            rm "$FILE"
        done
    fi
    sleep 5
done
