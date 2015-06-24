#!/usr/bin/env bash

echo "Giving the OS enough time to initialize..."
sleep 30

echo "Installing base packages"

# Enable multiverse
perl -pi.orig -e 'next if /-backports/; s/^# (deb .* multiverse)$/$1/' /etc/apt/sources.list

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y \
  autoconf \
  automake \
  build-essential \
  bison \
  curl \
  ec2-api-tools \
  ec2-ami-tools \
  gdb \
  git-core \
  libffi-dev \
  libgdbm3 \
  libgdbm-dev \
  libreadline6 \
  libreadline6-dev \
  libssl-dev \
  libssl0.9.8 \
  libcurl4-openssl-dev \
  libyaml-dev \
  libsqlite3-0 \
  libsqlite3-dev \
  libxml2-dev \
  libxslt1-dev \
  libpcre3 \
  libpcre3-dev \
  libc6-dev \
  libncurses5-dev \
  libtool \
  libmysqlclient-dev \
  mdadm \
  monit \
  mysql-client-5.6 \
  nodejs \
  ntp \
  openjdk-7-jdk \
  openssl \
  pkg-config \
  redis-server \
  sqlite3 \
  wget \
  zlib1g \
  zlib1g-dev

# Install Microsoft fonts, pre-accept the EULA
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get -y install ttf-mscorefonts-installer

# Install PrinceXML
pushd /tmp
  curl -O http://www.princexml.com/download/prince_9.0-5_ubuntu14.04_amd64.deb
  dpkg -i prince_9.0-5_ubuntu14.04_amd64.deb
popd

# Install custom build of ImageMagick
#
# Preconfigured in /tmp with:
# ./configure --prefix=/usr/local/imagemagick && make
imagemagick_version="6.8.9-7"
apt-get build-dep imagemagick -y
pushd /tmp
  curl -O http://packages.machines.io/imagemagick/14.04/ImageMagick-$imagemagick_version.tgz
  tar zxvf ImageMagick-$imagemagick_version.tgz
  cd ImageMagick-$imagemagick_version
  make install
  ln -s /usr/local/imagemagick/bin/* /usr/local/bin
popd

# Install FFMpeg
add-apt-repository ppa:mc3man/trusty-media -y
apt-get update
apt-get install ffmpeg -y

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

# Fetch system ruby and install gems
ruby_version="2.2.2"
bundler_version="1.10.4"
mkdir /opt/rubies

pushd /opt/rubies
  curl -O http://packages.machines.io/rubies/trusty/$ruby_version.tgz
  tar zxf $ruby_version.tgz
popd

rm -rf /usr/local/rbenv/versions
ln -nfs /opt/rubies /usr/local/rbenv/versions

/opt/rubies/$ruby_version/bin/gem install bundler --no-rdoc --no-ri -v $bundler_version

rbenv global $ruby_version
rbenv rehash

# Add deploy user
adduser --disabled-password --gecos "" deploy

# Add deploy user to sudo with no password
echo "deploy ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Allow overcommitting memory (forking with copy-on-write)
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
