FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        libreoffice \
        poppler-utils \
        imagemagick \
        python3-minimal \
        fontconfig \
        fonts-montserrat \
        fonts-liberation \
        fonts-dejavu \
    && fc-cache -f \
    && rm -rf /var/lib/apt/lists/*

# Autoriser la lecture/ecriture des PDF (chemin different selon ImageMagick 6 ou 7)
RUN for f in /etc/ImageMagick-*/policy.xml; do \
        [ -f "$f" ] && sed -i 's/rights="none" pattern="PDF"/rights="read | write" pattern="PDF"/' "$f"; \
    done; true

WORKDIR /app
COPY ./loop.sh ./fix_srcrect.py ./
RUN chmod +x loop.sh fix_srcrect.py
RUN mkdir -p data/fileToConvert/reports data/pdf data/sep-pdf data/png data/archives data/work

ENTRYPOINT ["/app/loop.sh"]
