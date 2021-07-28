#!/bin/sh

# generate and install certificate
sudo apt install -y libnss3-tools
wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-linux-amd64 -O mkcert
chmod +x ./mkcert
./mkcert -install
./mkcert "*.dev.env" "dev.env"
mv ./*.pem ./conf/

# register domain resolution in local systemd DNS configuration
# see https://gist.github.com/brasey/fa2277a6d7242cdf4e4b7c720d42b567#solution
resolv=/etc/systemd/resolved.conf
grep -qxF 'DNS=127.0.0.1' $resolv || cat <<EOT | sudo tee -a $resolv > /dev/null
DNS=127.0.0.1
Domains=~dev.env
EOT
sudo service systemd-resolved restart

# set custom environment variables
cat <<EOT > .env
DEVENV_WEB_PATH=/var/www/
EOT

# create shared docker network
docker network create devenv

# run the application
docker-compose up -d