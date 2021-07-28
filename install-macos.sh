#!/bin/sh

# generate and install certificate
brew install mkcert
brew install nss
mkcert -install
mkcert "*.dev.env" "dev.env"
mv ./*.pem ./conf/

# register domain resolution in local systemd DNS configuration
# see https://medium.com/@jamieeduncan/i-recently-moved-to-a-macbook-for-my-primary-work-laptop-7c704dbaff59
sudo mkdir -p /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/dev.env'

# create shared docker network
docker network create devenv

# set custom environment variables
cat <<EOT > .env
DEVENV_WEB_PATH=~/www
EOT


# run the application
docker-compose up -d
