#!/bin/bash - 

. /opt/chambana/lib/common.sh

CHECK_BIN "jekyll"
CHECK_BIN "git"
CHECK_BIN "a2ensite"
CHECK_BIN "a2enmod"
CHECK_VAR GITHUB_USER
CHECK_VAR GITHUB_REPO

#If subdir not defined, set default.
SUBDIR=${SUBDIR:-/}
GITHUB_BRANCH=${GITHUB_BRANCH:-"master"}

MSG "Cloning repository..."
git clone -b ${GITHUB_BRANCH} --single-branch https://github.com/${GITHUB_USER}/${GITHUB_REPO} /tmp/www
[[ $? -eq 0 ]] || { ERR "Failed to clone repository, aborting."; exit 1; }
[[ -d /tmp/www/${SUBDIR} ]] || { ERR "Subdirectory $SUBDIR does not exist, aborting."; exit 1; }

MSG "Installing site..."
cd /tmp/www/${SUBDIR}
jekyll build -d /var/www/html
chown -R www-data:www-data /var/www/html
rm -rf /tmp/www

MSG "Cleaning Apache logs..."
rm -rf /var/log/apache2/*
ln -sf /var/log/apache2/access.log /dev/stdout
ln -sf /var/log/apache2/error.log /dev/stderr

MSG "Configuring Apache..."
a2ensite 000-default.conf
a2enmod userdir

MSG "Starting services..."
supervisord -c /etc/supervisor/supervisord.conf
