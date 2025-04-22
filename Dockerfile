FROM ubuntu:latest
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y libreoffice
RUN apt-get install -y poppler-utils
RUN apt-get install -y imagemagick
RUN sed -i 's/rights="none" pattern="PDF"/rights="read | write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml



WORKDIR /app
COPY ./loop.sh .
RUN chmod +x loop.sh
RUN mkdir data
RUN mkdir ./data/fileToConvert
RUN mkdir ./data/fileToConvert/reports
RUN mkdir ./data/pdf
RUN mkdir ./data/sep-pdf
RUN mkdir ./data/png
RUN mkdir ./data/archives

ENTRYPOINT ["/app/loop.sh"]
