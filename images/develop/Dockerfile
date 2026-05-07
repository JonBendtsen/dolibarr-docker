# ==============================================================================
# STAGE 1: BUILDER
# Compiles extensions, installs dependencies, and prepares the application
# ==============================================================================
ARG ARCH=
FROM ${ARCH}dunglas/frankenphp:1-php8.2 AS builder

LABEL maintainer="The Dolibarr foundation <contact@dolibarr.org>"

# Environment Variables
ENV DOLI_VERSION=develop
ENV DOLI_VERSION_FOR_INIT_DEMO=23.0
ENV DOLI_INSTALL_AUTO=1
ENV DOLI_PROD=1

ENV DOLI_DB_TYPE=mysqli
ENV DOLI_DB_HOST=mysql
ENV DOLI_DB_HOST_PORT=3306
ENV DOLI_DB_NAME=dolidb
ENV DOLI_DB_SSL=false

ENV DOLI_URL_ROOT='http://localhost'

ENV DOLI_AUTH=dolibarr
ENV DOLI_LDAP_HOST=127.0.0.1
ENV DOLI_LDAP_PORT=389
ENV DOLI_LDAP_VERSION=3
ENV DOLI_LDAP_SERVER_TYPE=openldap
ENV DOLI_LDAP_LOGIN_ATTRIBUTE=uid
ENV DOLI_LDAP_DN='ou=users,dc=my-domain,dc=com'
ENV DOLI_LDAP_FILTER=''
ENV DOLI_LDAP_BIND_DN=''
ENV DOLI_LDAP_BIND_PASS=''
ENV DOLI_LDAP_DEBUG=false

ENV DOLI_CRON=0

ENV WWW_USER_ID=33
ENV WWW_GROUP_ID=33

ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV PHP_INI_MEMORY_LIMIT=256M
ENV PHP_INI_UPLOAD_MAX_FILESIZE=20M
ENV PHP_INI_POST_MAX_SIZE=22M
ENV PHP_INI_ALLOW_URL_FOPEN=0

# 1. Install System Dependencies (Build Time)
RUN apt-get update -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libkrb5-dev \
        libldap2-dev \
        libldap-common \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        libtidy-dev \
        libbz2-dev \
        default-mysql-client \
        postgresql-client \
        vim-tiny \
        cron \
        locales \
        tzdata \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "UTC" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*


    # 3. Set Environment Variables for the container
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ... (Continue with install-php-extensions)

# 2. Compile PHP Extensions
RUN install-php-extensions \
    gd \
    calendar \
    intl \
    mysqli \
    pdo_mysql \
    soap \
    zip \
    opcache \
    tidy \
    pgsql \
    pdo_pgsql \
    ldap \
    bz2 \
    && mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini \
    && sed -i 's/expose_php = On/expose_php = Off/g' ${PHP_INI_DIR}/php.ini


# 3. AGGRESSIVE CLEANUP (Critical for Multi-Stage)
# We explicitly remove the build tools that install-php-extensions leaves behind
RUN apt-get remove -y --purge \
    gcc \
    g++ \
    cpp \
    make \
    autoconf \
    automake \
    libtool \
    dpkg-dev \
    binutils \
    libc6-dev \
    libc-dev-bin \
    linux-libc-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 3. Download and Prepare Dolibarr Application
RUN curl -fLSs https://github.com/Dolibarr/dolibarr/archive/${DOLI_VERSION}.tar.gz |\
    tar -C /tmp -xz && \
    mkdir -p /app/public /app/documents /app/scripts /app/public/custom && \
    cp -r /tmp/dolibarr-${DOLI_VERSION}/htdocs/* /app/public/ && \
    cp -r /tmp/dolibarr-${DOLI_VERSION}/scripts /app/ && \
    rm -rf /tmp/*

# Set permissions (optional, depending on your runtime user setup)
RUN chown -R www-data:www-data /app

# ==============================================================================
# STAGE 2: RUNTIME
# Minimal image containing only the binary, extensions, and app code
# ==============================================================================
# Use the standard runtime image (no -builder suffix)
FROM ${ARCH}dunglas/frankenphp:1-php8.2 AS runtime

# Copy environment variables from builder (optional, but good for consistency)
ENV DOLI_VERSION=develop
ENV DOLI_INSTALL_AUTO=1
ENV DOLI_PROD=1
ENV DOLI_DB_TYPE=mysqli
ENV DOLI_DB_HOST=mysql
ENV DOLI_DB_HOST_PORT=3306
ENV DOLI_DB_NAME=dolidb
ENV DOLI_DB_SSL=false
ENV DOLI_URL_ROOT='http://localhost'
ENV DOLI_AUTH=dolibarr
ENV DOLI_LDAP_HOST=127.0.0.1
ENV DOLI_LDAP_PORT=389
ENV DOLI_LDAP_VERSION=3
ENV DOLI_LDAP_SERVER_TYPE=openldap
ENV DOLI_LDAP_LOGIN_ATTRIBUTE=uid
ENV DOLI_LDAP_DN='ou=users,dc=my-domain,dc=com'
ENV DOLI_LDAP_FILTER=''
ENV DOLI_LDAP_BIND_DN=''
ENV DOLI_LDAP_BIND_PASS=''
ENV DOLI_LDAP_DEBUG=false
ENV DOLI_CRON=0
ENV WWW_USER_ID=33
ENV WWW_GROUP_ID=33
ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV PHP_INI_MEMORY_LIMIT=256M
ENV PHP_INI_UPLOAD_MAX_FILESIZE=20M
ENV PHP_INI_POST_MAX_SIZE=22M
ENV PHP_INI_ALLOW_URL_FOPEN=0

# 1. Copy the FrankenPHP Binary (if you built a custom one)
# If using the standard image, this line is optional but safe.
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp

# 2. CRITICAL: Copy the PHP Extensions (.so files)
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# 3. CRITICAL: Copy the Configuration Files (.ini files)
# This is what tells PHP to LOAD the extensions we just copied.
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# 4. Copy the modified php.ini (for global settings like expose_php)
COPY --from=builder ${PHP_INI_DIR}/php.ini ${PHP_INI_DIR}/php.ini

# 5. Copy Application Code
COPY --from=builder /app /app

# 6. Install Runtime Libraries for Debian Trixie (Robust Version)
RUN apt-get update && \
    # Try to install the standard packages first
    apt-get install -y --no-install-recommends \
        libpng16-16t64 \
        libjpeg62-turbo \
        libfreetype6 \
        libavif16 \
        libwebp7 \
        libxpm4 \
        libbz2-1.0 \
        libsasl2-2 \
        libldap2 \
        libkrb5-3 \
        libicu76 \
        libpq5 \
        libtidy58 \
        libzip5 \
        default-mysql-client \
        postgresql-client \
        locales \
        tzdata \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "UTC" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && apt-get remove -y --purge gcc g++ cpp make autoconf automake libtool dpkg-dev binutils libc6-dev libc-dev-bin linux-libc-dev \
                        mailcap \
                        file \
                        libgdbm6t64 \
                        libmagic-mgc \
                        libmagic1t64 \
                        libperl5.40 \
                        media-types \
                        xz-utils \
                        libperl5.40 \
                        libgdbm6t64 \
                        file  libmagic1t64 libpkgconf3 mailcap media-types  pkg-config pkgconf pkgconf-bin re2c xz-utils \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# 2. Set Environment Variables
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8


# Expose port
EXPOSE 80

# Define volumes
VOLUME /app/documents
VOLUME /app/public/custom

# Set working directory
WORKDIR /app

# Default command (adjust if your base image uses a different entrypoint)
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]