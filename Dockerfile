# syntax=docker/dockerfile:1.4
FROM python:3.9

ARG BUILD_DATE
LABEL build_date="Build-date:- ${BUILD_DATE}"
LABEL maintainer="darthShadow"

ARG TARGETARCH
# latest
ARG TAUTULLI_RELEASE

ENV TZ="UTC" PGID="1000" PUID="1000"

ENV DEBIAN_FRONTEND="noninteractive"

# Inform app this is a docker env
ENV TAUTULLI_DOCKER="True"

# Install dependencies
RUN echo "**** Install Dependencies ****" && \
    apt-get -y update && \
    apt-get -y install --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        cron \
        curl \
        gdb \
        gosu \
        htop \
        jq \
        less \
        net-tools \
        openssl \
        vim \
        wget && \
    echo "**** Upgrade Packages ****" && \
    apt-get -y upgrade && \
    echo "**** Cleanup ****" && \
    apt-get -y autoremove && \
    apt-get -y purge && \
    apt-get -y clean && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

# Setup tautulli
RUN echo "**** Setting Up Tautulli ****" && \
    mkdir -p /app/tautulli && \
    if [ "x${TAUTULLI_RELEASE}" = "x" ]; then \
        TAUTULLI_RELEASE=$(curl -sX GET "https://api.github.com/repos/Tautulli/Tautulli/releases/latest" \
        | jq -r '. | .tag_name'); \
    fi && \
    echo "**** Downloading Tautulli Release: ${TAUTULLI_RELEASE} ****" && \
    curl --user-agent "Mozilla" -o /tmp/tautulli.tar.gz -L \
        "https://github.com/Tautulli/Tautulli/archive/${TAUTULLI_RELEASE}.tar.gz" && \
    tar -xf \
        /tmp/tautulli.tar.gz -C \
        /app/tautulli --strip-components=1 && \
    echo "**** Set Permissions ****" && \
    groupadd -g "${PGID}" tautulli && \
    useradd -u "${PUID}" -g "${PGID}" tautulli && \
    echo "**** Create config directory ****" && \
    mkdir /config && \
    touch /config/DOCKER && \
    echo "**** Hard Coding Versioning ****" && \
    echo "${TAUTULLI_RELEASE}" > /app/tautulli/version.txt && \
    echo "master" > /app/tautulli/branch.txt && \
    echo "**** Install pip dependencies ****" && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --upgrade \
        --extra-index-url https://www.piwheels.org/simple \
        -r /app/tautulli/requirements.txt && \
    echo "**** Cleanup ****" && \
    rm -rf \
        /root/.cache \
        /tmp/*

WORKDIR /app/tautulli

CMD [ "python", "Tautulli.py", "--verbose", "--datadir", "/config", "--nolaunch" ]

ENTRYPOINT [ "./start.sh" ]

HEALTHCHECK --start-period=90s CMD curl -ILfSs http://localhost:8181/status > /dev/null || curl -ILfkSs https://localhost:8181/status > /dev/null || exit 1

VOLUME /config

EXPOSE 8181
