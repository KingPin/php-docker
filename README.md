
# php-docker
php in docker for arm64 &amp; amd64 &amp; Arm32/v7

How to [set this image up via docker](https://sumguy.com/install-wordpress-with-php-fpm-caddy-via-docker/)

Following tags exist in both amd64 && arm64/aarch64 && armv7/armhf:

( lines with ~~strikethrough~~ are now deprectaed, they are available but wont be built via CI anymore. if you need those updated, open an issue. )
php-7 is still on bookworm.
php8.1 and higher have now migrated to bookworm. so if you use php8.3-fpm-bullseye OR php8.3-fpm-bullseye they both are the same image built on bookworm. this was done to not break containers for anyone still using bullseye as the tag.

 - 7-cli-bullseye
 - 7-cli-alpine 
 - 7-fpm-bullseye 
 - 7-fpm-alpine
 - 7-apache-bullseye
 - ~~8.0-cli-bullseye~~
 - ~~8.0-cli-alpine~~
 - ~~8.0-apache-bullseye~~
 - ~~8.0-fpm-bullseye~~
 - ~~8.0-fpm-alpine~~
 - 8.1-fpm-bookworm
 - 8.1-fpm-alpine
 - 8.1-apache-bookworm
 - 8.1-cli-bookworm
 - 8.1-cli-alpine
 - 8.2-fpm-bookworm
 - 8.2-fpm-alpine
 - 8.2-apache-bookworm
 - 8.2-cli-bookworm
 - 8.2-cli-alpine
 - 8.3-fpm-bookworm
 - 8.3-fpm-alpine
 - 8.3-apache-bookworm
 - 8.3-cli-bookworm
 - 8.3-cli-alpine

Contains the following php extensions : 

 - amqp
 - bcmath 
 - bz2
 - calendar
 - ctype  
 - exif  
 - gd (no av1 encoder on arm7 only)
 - intl 
 - imagick
 - imap
 - json
 - ldap
 - mbstring
 - mcrypt
 - memcached
 - mongodb
 - mysqli
 - opcache
 - pdo_mysql
 - pdo_pgsql
 - pgsql
 - redis
 - soap
 - snmp
 - sockets
 - tidy
 - timezonedb
 - uuid
 - vips
 - xsl 
 - yaml
 - zip
 - zstd

 Also contains latest **composer**
 
 For the apache version only it also contains **rewrite** mod

