#!/usr/bin/env bash

##############################################################
# Begin generic commands run across all roles
##############################################################

# Copy SSH keys for authentication
username=deploy

su $username -c "mkdir -p /home/$username/.ssh"
su $username -c "touch /home/$username/.ssh/authorized_keys"
(
cat <<'EOP'
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAs8S3Nj3JhcKd6XxNyN99e+TJdA2S1BM8++pKYeTQZzH62ij8jAvClHMJB13Lt7XcLqmO3MoSSJ+cXotSmurT70xaKp5ScGL0cY/4oIswdjIxqttoIBQ1CgfBM2JvHvRA9WstnlOmVd3VOSGknHt4NqPou8e0nuJF++08EthzPF1k+Is4TP7ySGAy5XLUfpvzxEhqXqkKDPADCoLW/N09GjASlft8AyliatpAuoHgM0Hul+808uIDPHkwPT4Dp6Fwnk1oNY2iT2vk5wtJ+SoXcPHXMJH8NqNxMG4CA5cew9NZGlKOEwxhnu2V3iOWCjL+sOylWMatbfAuLSex0Ra7aw== bensie@gmail.com
EOP
) > /home/$username/.ssh/authorized_keys

# Add apps dir in /mnt for application files
mkdir /mnt/apps
chown deploy:deploy /mnt/apps

##############################################################
# Begin role-specific commands
##############################################################

# Add nginx dir in /mnt for application logs
mkdir -p /mnt/nginx/log
