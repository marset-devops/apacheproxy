FROM ubuntu:18.04
LABEL maintainer="Fernando Marset <fernando.marset@gmail.com>"

# Install apache, PHP, and supplimentary programs. openssh-server, curl, and lynx-cur are for debugging the container.
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    apache2 curl git wget vim cron dos2unix tzdata software-properties-common

RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:certbot/certbot
RUN apt-get update&& DEBIAN_FRONTEND=noninteractive apt-get -y install python-certbot-apache

# Adjust system local time
RUN cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime


# Enable apache mods.
RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2enmod proxy_http
RUN a2enmod headers
RUN a2enmod remoteip

# Clean default virtualhosts and create generic virtualhost to redirect http => https

RUN ls /etc/apache2/sites-enabled/
RUN a2dissite 000-default.conf
RUN rm -f /etc/apache2/sites-available/*
ADD 000-redirect.conf /etc/apache2/sites-available/000-redirect.conf


# Update apache2 security.conf
RUN sed -i "s/ServerTokens OS/ServerTokens Prod/" /etc/apache2/conf-available/security.conf

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Expose apache.
EXPOSE 80
EXPOSE 443

# Add crontab jobs

RUN echo "# launch drive crontab" >> /etc/crontab
RUN echo "*/5 * * * *     root    wget https://drive.marsetvillar.com/cron.php -O /dev/null >/dev/null 2>&1"
### Create Master for config files
RUN tar -czvf /root/apache2.tar.gz /etc/apache2
RUN tar -czvf /root/letsencrypt.tar.gz /etc/letsencrypt

##custom entry point — needed by cron
ADD entrypoint /entrypoint
RUN chmod +x /entrypoint
RUN dos2unix /entrypoint
ENTRYPOINT ["/entrypoint"]

# Define mountable directories.
VOLUME ["/etc/apache2","/etc/letsencrypt","/var/log/"]

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]