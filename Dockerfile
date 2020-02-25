FROM php:7.4-fpm-stretch

RUN apt-get update && apt-get install -y libgmp-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev unzip \
    mysql-client libmagickwand-dev cron --no-install-recommends \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install gmp \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install zip

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
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


# 
# Permisos
# 
# RUN chown -R www-data:www-data /var/www

# Setup working directory
WORKDIR /var/www
