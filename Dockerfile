ARG SEAFILE_VERSION=8.0.7
ARG SYSTEM=bullseye

FROM --platform=${TARGETPLATFORM} debian:${SYSTEM} AS builder

ARG SEAFILE_VERSION
ARG TARGETARCH
ARG SYSTEM

RUN apt-get update -y && apt-get install -y \
    wget \
    sudo \
    python3 \
    python3-pip \
    # For compiling python memcached module.
    zlib1g-dev libmemcached-dev \
    # For compiling python mysqlclient module.
    libmariadb-dev \
    # For compiling python Pillow module.
    libjpeg-dev

# Install & update wheel here to speed up pip module installation.
RUN pip3 install --upgrade pip setuptools wheel

# Get seafile
WORKDIR /seafile

# Debug info
RUN printf "TARGET_ARCH=${TARGETARCH}"

# Download Seafile from official repo or build by ourselves.
RUN case "${TARGETARCH}" in \
    "amd64") \
      SEAFILE_URL="https://download.seadrive.org/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz" ;; \
    "arm64") \
      SEAFILE_URL="https://github.com/haiwen/seafile-rpi/releases/download/v${SEAFILE_VERSION}/seafile-server-${SEAFILE_VERSION}-${SYSTEM}-arm64v8.tar.gz" ;; \
    "arm/v7") \
      SEAFILE_URL="https://github.com/haiwen/seafile-rpi/releases/download/v${SEAFILE_VERSION}/seafile-server-${SEAFILE_VERSION}-${SYSTEM}-armv7l.tar.gz" ;; \
    esac ; \
    wget -c "${SEAFILE_URL}" -O seafile-server.tar.gz && \
    tar -zxvf seafile-server.tar.gz && \
    rm -f seafile-server.tar.gz

# For using TLS connection to LDAP/AD server with docker-ce.
RUN find /seafile/ \( -name "liblber-*" -o -name "libldap-*" -o -name "libldap_r*" -o -name "libsasl2.so*" -o -name "libcrypt.so.1" \) -delete

# Prepare media folder to be exposed
RUN mv seafile-server-${SEAFILE_VERSION}/seahub/media . && echo "${SEAFILE_VERSION}" > ./media/version

RUN pip3 install --timeout=3600 --target seafile-server-${SEAFILE_VERSION}/seahub/thirdpart --upgrade \
    gunicorn \
    jinja2 psd-tools \
    django==2.2.* \
    future \
    # Memcached
    pylibmc django-pylibmc \
    # captcha
    captcha django-simple-captcha \
    # MySQL
    mysqlclient sqlalchemy \
    # JWT for OnlyOffice
    pyjwt \
    # For video thumbnail
    Pillow moviepy

# Fix import not found when running seafile
RUN ln -s /usr/bin/python3 seafile-server-${SEAFILE_VERSION}/seafile/lib/python3.6

FROM debian:${SYSTEM}-slim AS seafile-server

ARG SEAFILE_VERSION

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
# Set default timezone.
ENV TZ America/Los_Angeles
ENV DEBIAN_FRONTEND noninteractive
# Change directory for matplotlib
ENV MPLCONFIGDIR /var/cache/matplotlib

WORKDIR /opt/seafile

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    locales \
    # For suport set local time zone.
    tzdata \
    sudo \
    procps \
    # For seafile-data backup
    rsync \
    # Support FUSE
    fuse \
    # For video thumbnail
    ffmpeg \
    # Memcache
    libmemcached11 \
    # MariaDB
    libmariadb-dev \
    python3 \
    python3-ldap \
    # Mysql init script requirement only. Will probably be useless in the future
    python3-pymysql && \
    rm -rf /var/lib/apt/lists/* ; \
    # Generate locale
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 ; \
    # Create Seafile User.
    useradd -ms /bin/bash -G sudo seafile && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R seafile:seafile /opt/seafile && \
    mkdir -p /var/cache/matplotlib && \
    chown -R seafile:seafile /var/cache/matplotlib

COPY --chown=seafile:seafile scripts /scripts

# Add version in container context
ENV SEAFILE_VERSION=${SEAFILE_VERSION}

COPY --from=builder --chown=seafile:seafile /seafile /opt/seafile

CMD ["/scripts/docker_entrypoint.sh"]
