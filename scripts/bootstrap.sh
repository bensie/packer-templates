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
  monit \
  mysql-client-5.6 \
  nodejs \
  npm \
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
imagemagick_version="6.9.7-2"
apt-get build-dep imagemagick -y
pushd /tmp
  curl -O http://www.imagemagick.org/download/ImageMagick-$imagemagick_version.tar.gz
  tar zxf ImageMagick-$imagemagick_version.tar.gz
  cd ImageMagick-$imagemagick_version
  ./configure --prefix=/usr/local/imagemagick
  make
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

# Although we have a sudo recipe, we don't have access to chef without this
echo 'Defaults !secure_path' >> /etc/sudoers

# Install rbenv
rbenv_install_path="/usr/local/rbenv"
git clone git://github.com/rbenv/rbenv.git $rbenv_install_path
cd $rbenv_install_path && git reset --hard 8f87f43e2286616cf3fb7b7bde7d924d7e1267a4

# Prepend Rbenv to the PATH for all users on interactive or non-interactive login
sed -i '1i export RBENV_ROOT=/usr/local/rbenv\nexport PATH=$RBENV_ROOT/shims:$RBENV_ROOT/bin:$PATH' /etc/profile
source /etc/profile

# Install ruby-build
pushd /tmp
  git clone https://github.com/rbenv/ruby-build.git
  cd ruby-build
  ./install.sh
popd

# Install Ruby
ruby_version="2.3.1"
$rbenv_install_path/bin/rbenv install $ruby_version

# Install Bundler
bundler_version="1.13.7"
$rbenv_install_path/versions/$ruby_version/bin/gem install bundler --no-rdoc --no-ri -v $bundler_version

# Set global default Ruby version
$rbenv_install_path/bin/rbenv global $ruby_version
$rbenv_install_path/bin/rbenv rehash

# Install rbenv-vars
mkdir -p $rbenv_install_path/plugins
git clone git://github.com/rbenv/rbenv-vars.git $rbenv_install_path/plugins/rbenv-vars
cd $rbenv_install_path/plugins/rbenv-vars && git reset --hard 3ffc5ce8cee564d3d892223add9548132ae22f8a

# Add deploy user
adduser --disabled-password --gecos "" deploy

# Add deploy user to sudo with no password
echo "deploy ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Allow overcommitting memory (forking with copy-on-write)
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
