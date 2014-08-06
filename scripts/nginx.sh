#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Install Phusion PGP Key
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7

# Add HTTPS support for APT
apt-get install apt-transport-https ca-certificates

# Create /etc/apt/sources.list.d/passenger.list
echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' > /etc/apt/sources.list.d/passenger.list

# Secure passenger.list
chown root: /etc/apt/sources.list.d/passenger.list
chmod 600 /etc/apt/sources.list.d/passenger.list

# Update APT cache
apt-get update

# Install packages
apt-get -y install nginx-extras passenger

# Allow the deploy user to edit /etc/nginx/sites-enabled
chown deploy:deploy /etc/nginx/sites-enabled

# Remove the default virtualhost symlink
rm /etc/nginx/sites-enabled/default

# Make /var/www directory
mkdir /var/www
