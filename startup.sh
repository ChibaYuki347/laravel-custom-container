#!/bin/bash
# environment settings for App Service Environment
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# SSH setting for app service
set -e
service ssh start

# Config Cache for Laravel
cd /var/www && php artisan config:cache

# default CMD from Dockerfile
apache2-foreground