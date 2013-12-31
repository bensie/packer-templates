#!/usr/bin/env bash

echo "Giving the OS enough time to initialize..."
sleep 30

echo "Installing base packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y build-essential bison openssl libreadline6 libreadline6-dev curl wget git-core zlib1g zlib1g-dev libssl-dev libssl0.9.8 libcurl4-openssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool imagemagick libmysqlclient-dev mysql-client openjdk-7-jdk pkg-config mdadm libpcre3 libpcre3-dev gdb

echo "Installing the backported kernel"
apt-get install -y linux-image-generic-lts-raring linux-headers-generic-lts-raring

# Set timezone
echo 'America/Los_Angeles' | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Install Rbenv
git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv
cd /usr/local/rbenv && git reset --hard 783618b89cb80b74f1daf03679081dd1233f49eb

# Install rbenv-vars
mkdir -p /usr/local/rbenv/plugins
git clone git://github.com/sstephenson/rbenv-vars.git /usr/local/rbenv/plugins/rbenv-vars
cd /usr/local/rbenv/plugins/rbenv-vars && git reset --hard v1.2.0

# Prepend Rbenv to the PATH for all users on interactive or non-interactive login
sed -i '1i export RBENV_ROOT=/usr/local/rbenv\nexport PATH=$RBENV_ROOT/shims:$RBENV_ROOT/bin:$PATH' /etc/profile
source /etc/profile

# Although we have a sudo recipe, we don't have access to chef without this
echo 'Defaults !secure_path' >> /etc/sudoers

##
# Fetch system ruby and install gems

mkdir /opt/rubies

pushd /opt/rubies
  curl -O http://packages.machines.io/rubies/2.0.0-p353.tgz
  tar zxf 2.0.0-p353.tgz
popd

rm -rf /usr/local/rbenv/versions
ln -nfs /opt/rubies /usr/local/rbenv/versions

/opt/rubies/2.0.0-p353/bin/gem install chef --no-rdoc --no-ri -v 11.8.2

rbenv global 2.0.0-p353
rbenv rehash

##
# Install NodeJS for JS Runtime

pushd /opt
  curl -O http://packages.machines.io/nodejs/node-v0.10.20.tgz
  tar zxvf node-v0.10.20.tgz
  pushd node-v0.10.20
    make install
  popd
  rm -rf node-v0.10.20
  rm -f node-v0.10.20.tgz
popd

##
# Configure Chef

mkdir -p /etc/chef
mkdir -p /var/log/chef

mkdir -p /home/ubuntu/chef-solo/data_bags
mkdir -p /home/ubuntu/chef-solo/cookbooks
mkdir -p /home/ubuntu/chef-solo/custom-cookbooks
chown -R ubuntu:ubuntu /home/ubuntu/chef-solo

git clone git://github.com/machines/cookbooks.git /home/ubuntu/chef-solo/cookbooks

echo 'file_cache_path "/home/ubuntu/chef-solo"' > /etc/chef/solo.rb
echo 'data_bag_path "/home/ubuntu/chef-solo/data_bags"' >> /etc/chef/solo.rb
echo 'cookbook_path ["/home/ubuntu/chef-solo/cookbooks", "/home/ubuntu/chef-solo/custom-cookbooks"]' >> /etc/chef/solo.rb
echo 'json_attribs "/home/ubuntu/chef-solo/node.json"' >> /etc/chef/solo.rb
echo 'log_location "/var/log/chef/solo.log"' >> /etc/chef/solo.rb
