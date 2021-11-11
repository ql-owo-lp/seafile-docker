FROM phusion/baseimage:focal-1.0.0

ENV SEAFILE_SERVER=seafile-server
ENV SEAFILE_VERSION=8.0.7

ARG SERVER_ARCH=arm64v8
ARG SEAFILE_RELEASE_URL=https://github.com/haiwen/seafile-rpi/releases/download/v${SEAFILE_VERSION}/seafile-server-${SEAFILE_VERSION}-focal-${SERVER_ARCH}.tar.gz

RUN apt-get update --fix-missing

# Utility tools
RUN apt-get install -y vim htop net-tools psmisc wget curl git

# For suport set local time zone.
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install tzdata -y

# Nginx
RUN apt-get install -y nginx

# Custom section start -------------------------
RUN apt-get install -y \
    libjpeg-dev \
    zlib1g-dev \
    libtiff5-dev \
    libfreetype6-dev \
    libwebp-dev \
    python3-setuptools \
    kmod \
    unzip \
    fuse

# fuse
RUN addgroup fuse && mkdir -p /shared && mkdir -p /shared/fuse

#
RUN apt-get install -y libmemcached-dev
# Custom section end --------------------------

RUN apt-get install -y libmariadbclient-dev

# Python3
RUN apt-get install -y python3 python3-pip python3-setuptools
RUN python3.6 -m pip install --upgrade pip && rm -r /root/.cache/pip

RUN pip3 install --timeout=3600 click termcolor colorlog pymysql \
    django==2.2.* && rm -r /root/.cache/pip

RUN pip3 install --timeout=3600 future mysqlclient Pillow pylibmc captcha jinja2 \
    sqlalchemy django-pylibmc django-simple-captcha pyjwt && \
    rm -r /root/.cache/pip


# Scripts
RUN mkdir /tmp-downloads
WORKDIR /tmp-downloads
RUN wget https://github.com/haiwen/seafile-docker/archive/master.zip
RUN unzip master.zip
RUN mv seafile-docker-master/seafile_8.0/scripts /scripts
RUN mv seafile-docker-master/image/seafile_8.0/services /services
RUN mv seafile-docker-master/image/seafile_8.0/templates /templates
RUN rm -rf /tmp-downloads
RUN chmod u+x /scripts/*

RUN mkdir -p /etc/my_init.d && \
    rm -f /etc/my_init.d/* && \
    cp /scripts/create_data_links.sh /etc/my_init.d/01_create_data_links.sh

RUN mkdir -p /etc/service/nginx && \
    rm -f /etc/nginx/sites-enabled/* /etc/nginx/conf.d/* && \
    mv /services/nginx.conf /etc/nginx/nginx.conf && \
    mv /services/nginx.sh /etc/service/nginx/run

# Seafile
WORKDIR /opt/seafile

RUN mkdir -p /opt/seafile/ && cd /opt/seafile/ && \
    wget -c ${SEAFILE_RELEASE_URL} -O seafile-server.tar.gz && \
    tar -zxvf seafile-server.tar.gz && \
    rm -f seafile-server.tar.gz

# For using TLS connection to LDAP/AD server with docker-ce.
RUN find /opt/seafile/ \( -name "liblber-*" -o -name "libldap-*" -o -name "libldap_r*" -o -name "libsasl2.so*" \) -delete

EXPOSE 80

CMD ["/sbin/my_init", "--", "/scripts/start.py"]
