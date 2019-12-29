FROM alpine
MAINTAINER Santosh <santosh@example.com>
## Install Apache and PHP
RUN apk add --update apache2 php-apache2 php-ctype php-pdo_mysql php-mysqli php-zip php-xml php-zlib php-opcache php-pdo_odbc php-soap php-pgsql php-pdo php-json php-openssl php-gd php-curl shadow php7-pecl-redis && rm -rf /var/cache/apk/*
## Remove PHP version exposure
RUN sed -ir 's/expose_php = On/expose_php = Off/' /etc/php7/php.ini
## Load redis extension in php
RUN echo 'extension=redis.so' >> /etc/php7/conf.d/redis.ini
## Expose port
EXPOSE 80
## Set working directory
WORKDIR /var/www/localhost/htdocs
## Run Apache
CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
## Add application code
COPY . /var/www/localhost/htdocs
