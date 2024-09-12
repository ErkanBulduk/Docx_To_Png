#!/bin/bash
echo beginning loop
set -e

while true
do
    if [ "$(ls -A $PWD/data/docx)" ]; then
        for FILE in $PWD/data/docx/*
        do 
            echo $FILE
            EXT="${FILE#*.}"
            echo $EXT
            NAME="${FILE##*/}" 
            NAME_NO_EXT="${NAME%.*}"
            if [ "$EXT" == "docx" ] || [ "$EXT" == "pptx" ] || [ "$EXT" == "pdf" ]
            then
                if [[ "$EXT" == "docx" ]] 
                then
                    echo docx found
                    echo converting $NAME_NO_EXT to pdf
                    libreoffice --headless --convert-to pdf "$FILE" --outdir $PWD/data/pdf
                    echo converting $NAME_NO_EXT to pdf Finish and waiting for separate
                    sleep 3
                elif [[ "$EXT" == "pptx" ]]
                then
                    echo pptx found
                    echo converting $NAME_NO_EXT to pdf
                    libreoffice --headless --convert-to pdf "$FILE" --outdir $PWD/data/pdf
                    echo converting $NAME_NO_EXT to pdf Finish and waiting for separate
                    sleep 3
                else
                    echo pdf found    
                    cp "$FILE" "$PWD/data/pdf"
                fi
                echo separating "$PWD/data/sep-pdf/$NAME_NO_EXT-%d.pdf" to pdf
                pdfseparate "$PWD/data/pdf/$NAME_NO_EXT.pdf" "$PWD/data/sep-pdf/$NAME_NO_EXT-%d.pdf"
                rm "$PWD/data/pdf/$NAME_NO_EXT.pdf"

                for PDF in $PWD/data/sep-pdf/*
                do
                    PDFNAME="${PDF##*/}" 
                    PDF_NO_EXT="${PDFNAME%.*}"
                    echo converting "$PWD/data/sep-pdf/$PDF_NO_EXT.pdf" to png
                    convert -density 300 "$PWD/data/sep-pdf/$PDF_NO_EXT.pdf" "$PWD/data/png/$PDF_NO_EXT.png"
                    # pdftoppm -png -r 300 "$PWD/data/sep-pdf/$PDF_NO_EXT.pdf" "$PWD/data/png/$PDF_NO_EXT"
                    sleep 1
                    rm "$PWD/data/sep-pdf/$PDF_NO_EXT.pdf"
                done
            else
                echo not docx, removing file
            fi
            echo Copy file to archives
            cp "$FILE" "$PWD/data/archives"
            echo Remove file
            rm "$FILE"
        done
    fi
    sleep 5
done
echo out of loop