# FROM httpd:2.4.63-alpine3.22
FROM httpd:2.4.63
LABEL org.opencontainers.image.authors="Ginger Mann <gmann@presidio.com>"

# RUN apt-get update && apt-get install -y \
#    apache2-dev \
#    build-essential \
#    php \
#    libapache2-mod-php \
#    && rm -rf /var/lib/apt/lists/*

# RUN apk update && \
#     apk add curl mod_auth_cas && \
#     # usermod -u 3186 www-data && \
#     chown -R www-data /usr/local/apache2

RUN apt-get update && \
    apt-get install -y libapache2-mod-auth-cas


#    ServerName ssh-01-bl-test.webtech.uits.abstracted.domain\n\
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY httpd-vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf
COPY alias.conf /usr/local/apache2/conf/extra/alias.conf
COPY auth_cas.conf /usr/local/apache2/conf/extra/auth_cas.conf

CMD ["httpd-foreground"]
