FROM debian:stable-slim

# ===================================================
# Package versions
# ===================================================

ARG MARIADB_VERSION=10.5

# PHP
ENV PHP_VERSION_1=7.2
ENV PHP_VERSION_2=7.3
ENV PHP_VERSION_3=7.4

# Timezone
ENV TZ=Europe/Berlin

# ===================================================
# Ports
# ===================================================

# NGINX
EXPOSE 80
EXPOSE 443

# BIND
EXPOSE 53

# ===================================================
# Base packages
# ===================================================

RUN apt update && \
    apt upgrade -y --no-install-recommends

RUN apt install -y --no-install-recommends \
    apt-listchanges \
    apt-transport-https \
	apt-utils \
    ca-certificates \
    curl \
    dirmngr \
    gnupg2 \
    locales \
    locales-all \
    lsb-release \
    software-properties-common \
    syslog-ng \
    unattended-upgrades \
    wget

# ===================================================
# Sources
# ===================================================

RUN echo "deb http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key \
    | apt-key add -

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8 && \
    add-apt-repository "deb [arch=amd64] http://ftp.hosteurope.de/mirror/mariadb.org/repo/${MARIADB_VERSION}/debian buster main"

RUN apt update

# ===================================================
# Froxlor service packages
# ===================================================

RUN apt install -y --no-install-recommends \
    awstats \
    bind9 \
    cron \
    letsencrypt \
    libnss-extrausers \
    logrotate \
    mariadb-client \
    nginx

# ===================================================
# PHP
# ===================================================

RUN apt install -y --no-install-recommends \
    php${PHP_VERSION_1} \
    php${PHP_VERSION_1}-common \
    php${PHP_VERSION_1}-bcmath \
    php${PHP_VERSION_1}-bz2 \
    php${PHP_VERSION_1}-cli \
    php${PHP_VERSION_1}-curl \
    php${PHP_VERSION_1}-fpm \
    php${PHP_VERSION_1}-gd \
    php${PHP_VERSION_1}-imap \
    php${PHP_VERSION_1}-intl \
    php${PHP_VERSION_1}-json \
    php${PHP_VERSION_1}-mbstring \
    php${PHP_VERSION_1}-mysql \
    php${PHP_VERSION_1}-opcache \
    php${PHP_VERSION_1}-xml \
    php${PHP_VERSION_1}-zip \
    php${PHP_VERSION_2} \
    php${PHP_VERSION_2}-common \
    php${PHP_VERSION_2}-bcmath \
    php${PHP_VERSION_2}-bz2 \
    php${PHP_VERSION_2}-cli \
    php${PHP_VERSION_2}-curl \
    php${PHP_VERSION_2}-fpm \
    php${PHP_VERSION_2}-gd \
    php${PHP_VERSION_2}-imap \
    php${PHP_VERSION_2}-intl \
    php${PHP_VERSION_2}-json \
    php${PHP_VERSION_2}-mbstring \
    php${PHP_VERSION_2}-mysql \
    php${PHP_VERSION_2}-opcache \
    php${PHP_VERSION_2}-xml \
    php${PHP_VERSION_2}-zip \
    php${PHP_VERSION_3} \
    php${PHP_VERSION_3}-common \
    php${PHP_VERSION_3}-bcmath \
    php${PHP_VERSION_3}-bz2 \
    php${PHP_VERSION_3}-cli \
    php${PHP_VERSION_3}-curl \
    php${PHP_VERSION_3}-fpm \
    php${PHP_VERSION_3}-gd \
    php${PHP_VERSION_3}-imap \
    php${PHP_VERSION_3}-intl \
    php${PHP_VERSION_3}-json \
    php${PHP_VERSION_3}-mbstring \
    php${PHP_VERSION_3}-mysql \
    php${PHP_VERSION_3}-opcache \
    php${PHP_VERSION_3}-xml \
    php${PHP_VERSION_3}-zip

# ===================================================
# AWStats
# ===================================================

RUN cp /usr/share/awstats/tools/awstats_buildstaticpages.pl /usr/bin/ && \
    mv /etc/awstats//awstats.conf /etc/awstats//awstats.model.conf && \
    sed -i.bak 's/^DirData/# DirData/' /etc/awstats//awstats.model.conf && \
    sed -i.bak 's|^\\(DirIcons=\\).*$|\\1\\"/awstats-icon\\"|' /etc/awstats//awstats.model.conf && \
    rm /etc/cron.d/awstats

# ===================================================
# Lib extrausers
# ===================================================

RUN mkdir -p /var/lib/extrausers && \
    touch /var/lib/extrausers/passwd && \
    touch /var/lib/extrausers/group && \
    touch /var/lib/extrausers/shadow

# ===================================================
# BIND DNS
# ===================================================

RUN echo "include \"/etc/bind/froxlor_bind.conf\";" >> /etc/bind/named.conf.local && \
    touch /etc/bind/froxlor_bind.conf && \
    chown bind:0 /etc/bind/froxlor_bind.conf && \
    chmod 0644 /etc/bind/froxlor_bind.conf

# ===================================================
# Froxlor user and groups
# ===================================================

RUN addgroup --gid 9999 froxlorlocal && \
    adduser --no-create-home --uid 9999 --ingroup froxlorlocal --shell /bin/false --disabled-password --gecos '' froxlorlocal && \
    adduser www-data froxlorlocal

# ===================================================
# Froxlor directories
# ===================================================

RUN mkdir -p /var/www && \
    mkdir -p /var/customers/logs && \
    mkdir -p /var/customers/mail && \
    mkdir -p /var/customers/webs && \
    mkdir -p /var/customers/tmp && \
    mkdir -p /etc/ssl/froxlor

# ===================================================
# Add configurations
# ===================================================

COPY ./etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./etc/nginx/fastcgi_params /etc/nginx/fastcgi_params
COPY ./etc/nginx/acme.conf /etc/nginx/acme.conf
COPY ./etc/nginx/conf.d/ /etc/nginx/conf.d/

COPY ./etc/cron.d/froxlor /etc/cron.d/froxlor

COPY ./etc/logrotate.d/froxlor /etc/logrotate.d/froxlor

COPY ./etc/nsswitch.conf /etc/nsswitch.conf

COPY ./start.sh /start.sh

# ===================================================
# Entrypoint
# ===================================================

ENTRYPOINT ["bash", "/start.sh"]
