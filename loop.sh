#!/bin/bash
echo beginning loop
set -e

# libreoffice="/c/Program Files/LibreOffice/program/soffice.exe"
pdfseparate="/c/Tools/poppler/Library/bin/pdfseparate"
pdftoppm="/c/Tools/poppler/Library/bin/pdftoppm"

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
            # dirname renvoie "." a la racine -> evite les chemins "data/pdf/./x.pdf"
            [ "$REL_DIR" = "." ] && REL_DIR=""
            PDF_OUTPUT_DIR="$PWD/data/pdf${REL_DIR:+/$REL_DIR}"

            mkdir -p "$PDF_OUTPUT_DIR"

            if [[ "$EXT" == "docx" || "$EXT" == "pptx" || "$EXT" == "pdf" ]]
            then
                if [[ "$EXT" == "docx" || "$EXT" == "pptx" ]]
                then
                    echo "$EXT found - converting $NAME_NO_EXT to PDF"
                    # On travaille sur une copie : fix_srcrect.py modifie le fichier
                    # en place, l'original doit rester intact pour les archives.
                    WORK_DIR="$PWD/data/work"
                    rm -rf "$WORK_DIR"
                    mkdir -p "$WORK_DIR"
                    cp "$FILE" "$WORK_DIR/$NAME"
                    python3 /app/fix_srcrect.py "$WORK_DIR/$NAME" || echo "fix_srcrect a echoue, conversion du fichier tel quel"
                    libreoffice --headless --convert-to pdf "$WORK_DIR/$NAME" --outdir "$PDF_OUTPUT_DIR"
                    rm -rf "$WORK_DIR"
                    echo "Conversion done for $NAME_NO_EXT"
                    sleep 3
                else
                    echo "PDF found - copying to $PDF_OUTPUT_DIR"
                    cp "$FILE" "$PDF_OUTPUT_DIR"
                fi

                PDF_FILE="$PDF_OUTPUT_DIR/$NAME_NO_EXT.pdf"
                SEP_DIR="$PWD/data/sep-pdf${REL_DIR:+/$REL_DIR}"
                PNG_DIR="$PWD/data/png${REL_DIR:+/$REL_DIR}"

                mkdir -p "$SEP_DIR" "$PNG_DIR"

                echo "Separating $PDF_FILE"
                pdfseparate "$PDF_FILE" "$SEP_DIR/$NAME_NO_EXT-%d.pdf"

                for PDF in "$SEP_DIR"/*.pdf
                do
                    [ -e "$PDF" ] || continue
                    PDFNAME="${PDF##*/}"
                    PDF_NO_EXT="${PDFNAME%.*}"
                    echo "Converting $PDF to PNG"

                    # Ecriture atomique. pdftoppm ecrit d'abord des fichiers
                    # caches ".tmp-*" dans le meme dossier, renommes seulement
                    # une fois l'image complete. Un renommage dans le meme
                    # systeme de fichiers est atomique : l'outil qui surveille
                    # data/png (n8n, Nextcloud...) ne peut plus lire une image
                    # encore en cours d'ecriture, ce qui donnait des PNG
                    # tronques ("image a moitie generee").
                    TMP_PREFIX="$PNG_DIR/.tmp-$PDF_NO_EXT"
                    rm -f "$TMP_PREFIX"*.png
                    if pdftoppm -png -r 300 "$PDF" "$TMP_PREFIX"
                    then
                        for TMP in "$TMP_PREFIX"*.png
                        do
                            [ -e "$TMP" ] || continue
                            mv -f "$TMP" "$PNG_DIR/${TMP##*/.tmp-}"
                        done
                    else
                        echo "pdftoppm a echoue pour $PDFNAME - PNG non publie"
                        rm -f "$TMP_PREFIX"*.png
                    fi

                    rm "$PDF"
                done
            else
                echo "Not docx/pptx/pdf, skipping"
            fi

            echo "Archiving $FILE"
            mkdir -p "$PWD/data/archives${REL_DIR:+/$REL_DIR}"
            cp "$FILE" "$PWD/data/archives${REL_DIR:+/$REL_DIR}"

            echo "Removing original $FILE"
            rm "$FILE"
        done
    fi
    sleep 5
done
