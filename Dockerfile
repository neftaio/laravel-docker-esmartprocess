FROM php:7.4-fpm

RUN apt-get update 
RUN apt-get install -y libgmp-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev unzip \
    default-mysql-client libmagickwand-dev cron zlib1g-dev libzip-dev \ 
    curl \ 
    --no-install-recommends
# Install NODE
# RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash 
# RUN bash -c "source /root/.bashrc && nvm install node" 
SHELL ["/bin/bash", "--login", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash 
RUN nvm install 13.5.0 && nvm use 13.5.0 
# Install exetencions
RUN pecl install imagick \
    && docker-php-ext-enable imagick \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install gmp \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install zip

# RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
#     && docker-php-ext-install gd
RUN docker-php-ext-configure gd \
    && docker-php-ext-install gd
RUN docker-php-ext-install calendar && docker-php-ext-configure calendar

# 
# 
# Install OCI8 extencion
# Oracle instantclient
# 
# 
# ORACLE oci 

RUN mkdir /opt/oracle \
    && cd /opt/oracle     

ADD instantclient-basic-linux.x64-12.1.0.2.0.zip /opt/oracle
ADD instantclient-sdk-linux.x64-12.1.0.2.0.zip /opt/oracle

# Install Oracle Instantclient
RUN  unzip /opt/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so \
    && ln -s /opt/oracle/instantclient_12_1/libclntshcore.so.12.1 /opt/oracle/instantclient_12_1/libclntshcore.so \
    && ln -s /opt/oracle/instantclient_12_1/libocci.so.12.1 /opt/oracle/instantclient_12_1/libocci.so \
    && rm -rf /opt/oracle/*.zip

ENV LD_LIBRARY_PATH  /opt/oracle/instantclient_12_1:${LD_LIBRARY_PATH}

# Install Oracle extensions
RUN echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8 \ 
    && docker-php-ext-enable \
    oci8 \ 
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_1,12.1 \
    && docker-php-ext-install \
    pdo_oci 

# 
# Configurations for PHP config init
# 
RUN touch /usr/local/etc/php/conf.d/espconfig.ini \
    && echo "upload_max_filesize = 50M;" >> /usr/local/etc/php/conf.d/espconfig.ini \
    && echo "max_execution_time = 300;" >> /usr/local/etc/php/conf.d/espconfig.ini


# Install composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Install PHP_CodeSniffer
RUN composer global require "squizlabs/php_codesniffer=*"

# 
# Permisos
# 
# RUN chown -R www-data:www-data /var/www

# Setup working directory
WORKDIR /var/www
