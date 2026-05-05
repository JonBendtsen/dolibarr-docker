# ==============================================================================
# STAGE 1: BUILDER
# Compiles extensions, installs dependencies, and prepares the application
# ==============================================================================
ARG ARCH=
FROM ${ARCH}dunglas/frankenphp:1-php8.2 AS builder

LABEL maintainer="The Dolibarr foundation <contact@dolibarr.org>"

# Environment Variables
ENV DOLI_VERSION=20.0.4
ENV DOLI_VERSION_FOR_INIT_DEMO=20.0
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
        default-mysql-client \
        postgresql-client \
        vim-tiny \
        cron \
    && rm -rf /var/lib/apt/lists/*

# 2. Compile PHP Extensions
RUN install-php-extensions \
    gd \
    intl \
    mysqli \
    pdo_mysql \
    soap \
    zip \
    opcache \
    tidy \
    pgsql \
    ldap \
    imap \
    && mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini \
    && sed -i 's/expose_php = On/expose_php = Off/g' ${PHP_INI_DIR}/php.ini

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
ENV DOLI_VERSION=20.0.4
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

# Copy the compiled FrankenPHP binary from builder
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp

# Copy the compiled PHP extensions from builder
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Copy the application code and directories from builder
COPY --from=builder /app /app

# Copy the configured php.ini from builder (if it wasn't baked into the base image)
# Note: The install-php-extensions script usually modifies the image's php.ini directly.
# If the base image is clean, we might need to copy the modified ini file.
# However, since we ran the sed command in the builder, the extensions are active there.
# We rely on the extensions being copied above. The ini settings are usually global.
# If you need the specific php.ini modifications, copy it:
COPY --from=builder ${PHP_INI_DIR}/php.ini ${PHP_INI_DIR}/php.ini

# Expose port
EXPOSE 80

# Define volumes
VOLUME /app/documents
VOLUME /app/public/custom

# Set working directory
WORKDIR /app

# Default command (adjust if your base image uses a different entrypoint)
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]