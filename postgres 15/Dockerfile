#base image
FROM  postgres:15-alpine

LABEL org.opencontainers.image.authors="Sylvain Goubaud"
ARG project=backup-postgres-minio
ARG version=15.7.2

LABEL patch="Ajout de plusieurs options pour le dump - corrections"
LABEL progam-name=${project}
LABEL version=${version}

# Update system
ENV DEBIAN_FRONTEND noninteractive
RUN apk update && \
    apk add	apk-cron \
            lsb-release \
            figlet \
            curl

RUN curl https://dl.min.io/client/mc/release/linux-arm64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc_arm64

RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc_amd64

RUN chmod +x $HOME/minio-binaries/mc*
RUN export PATH=$PATH:$HOME/minio-binaries/

COPY resources/docker-entrypoint.sh /usr/local/bin/
COPY resources/backup.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh

ENV DOCKERFILE_VERSION=${version}

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["run-cron"]
