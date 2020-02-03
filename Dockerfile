FROM php:7.2-apache
RUN echo '' | pecl install -o -f redis && rm -rf /tmp/pear && docker-php-ext-enable redis
RUN docker-php-ext-install pdo pdo_mysql mysqli
RUN echo "extension=redis.so" > $(php -i 2>/dev/null| grep 'php.ini' | awk '{print $NF}')/conf.d/redis.ini
RUN echo 'extension=mysqli.so' > $(php -i 2>/dev/null| grep 'php.ini' | awk '{print $NF}')/conf.d/mysqli.ini
COPY . /var/www/html
RUN mv -f /var/www/html/000-default.conf /etc/apache2/sites-enabled/000-default.conf
EXPOSE 80/tcp
