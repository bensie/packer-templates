#!/usr/bin/env bash

echo "Giving the OS enough time to initialize..."
sleep 30

echo "Installing base packages"

# Enable multiverse
perl -pi.orig -e 'next if /-backports/; s/^# (deb .* multiverse)$/$1/' /etc/apt/sources.list

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y build-essential bison openssl libreadline6 libreadline6-dev curl wget git-core zlib1g zlib1g-dev libssl-dev libssl0.9.8 libcurl4-openssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool imagemagick libmysqlclient-dev mysql-client-5.6 openjdk-7-jdk pkg-config mdadm libpcre3 libpcre3-dev gdb nodejs ec2-api-tools ec2-ami-tools

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
mkdir /opt/rubies

pushd /opt/rubies
  curl -O http://packages.machines.io/rubies/2.1.2.tgz
  tar zxf 2.1.2.tgz
popd

rm -rf /usr/local/rbenv/versions
ln -nfs /opt/rubies /usr/local/rbenv/versions

/opt/rubies/2.1.2/bin/gem install bundler --no-rdoc --no-ri -v 1.6.5

rbenv global 2.1.2
rbenv rehash

# Add deploy user
adduser --disabled-password --gecos "" deploy

# Add deploy user to sudo with no password
$username=deploy
echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Copy SSH keys for authentication
su $username -c "mkdir -p /home/$username/.ssh"
su $username -c "touch /home/$username/.ssh/authorized_keys"
(
cat <<'EOP'
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAs8S3Nj3JhcKd6XxNyN99e+TJdA2S1BM8++pKYeTQZzH62ij8jAvClHMJB13Lt7XcLqmO3MoSSJ+cXotSmurT70xaKp5ScGL0cY/4oIswdjIxqttoIBQ1CgfBM2JvHvRA9WstnlOmVd3VOSGknHt4NqPou8e0nuJF++08EthzPF1k+Is4TP7ySGAy5XLUfpvzxEhqXqkKDPADCoLW/N09GjASlft8AyliatpAuoHgM0Hul+808uIDPHkwPT4Dp6Fwnk1oNY2iT2vk5wtJ+SoXcPHXMJH8NqNxMG4CA5cew9NZGlKOEwxhnu2V3iOWCjL+sOylWMatbfAuLSex0Ra7aw== bensie@gmail.com
EOP
) > /home/$username/.ssh/authorized_keys