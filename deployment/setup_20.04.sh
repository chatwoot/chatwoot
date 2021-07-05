#!/usr/bin/env bash

# Description: Chatwoot installation script
# OS: Ubuntu 20.04 LTS / Ubuntu 20.10
# Script Version: 0.5
# Run this script as root

apt update && apt upgrade -y
apt install -y curl
curl -sL https://deb.nodesource.com/setup_12.x | bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt update

apt install -y \
	git software-properties-common imagemagick libpq-dev \
    libxml2-dev libxslt1-dev file g++ gcc autoconf build-essential \
    libssl-dev libyaml-dev libreadline-dev gnupg2 nginx redis-server \
    redis-tools postgresql postgresql-contrib certbot \
    python3-certbot-nginx nodejs yarn patch ruby-dev zlib1g-dev liblzma-dev \
    libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev nginx-full

adduser --disabled-login --gecos "" chatwoot

gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
addgroup chatwoot rvm

pg_pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15 ; echo '')
sudo -i -u postgres psql << EOF
\set pass `echo $pg_pass`
CREATE USER chatwoot CREATEDB;
ALTER USER chatwoot PASSWORD :'pass';
ALTER ROLE chatwoot SUPERUSER;
UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';
DROP DATABASE template1;
CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UNICODE';
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';
\c template1
VACUUM FREEZE;
EOF

systemctl enable redis-server.service
systemctl enable postgresql

secret=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 63 ; echo '')
RAILS_ENV=production

sudo -i -u chatwoot << EOF
rvm --version
rvm autolibs disable
rvm install "ruby-2.7.3"
rvm use 2.7.3 --default

git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot
if [[ -z "$1" ]]; then
git checkout master;
else
git checkout $1;
fi
bundle
yarn

cp .env.example .env
sed -i -e "/SECRET_KEY_BASE/ s/=.*/=$secret/" .env
sed -i -e '/REDIS_URL/ s/=.*/=redis:\/\/localhost:6379/' .env
sed -i -e '/POSTGRES_HOST/ s/=.*/=localhost/' .env
sed -i -e '/POSTGRES_USERNAME/ s/=.*/=chatwoot/' .env
sed -i -e "/POSTGRES_PASSWORD/ s/=.*/=$pg_pass/" .env
sed -i -e '/RAILS_ENV/ s/=.*/=$RAILS_ENV/' .env

RAILS_ENV=production bundle exec rake db:create
RAILS_ENV=production bundle exec rake db:reset
rake assets:precompile RAILS_ENV=production
EOF

cp /home/chatwoot/chatwoot/deployment/chatwoot-web.1.service /etc/systemd/system/chatwoot-web.1.service
cp /home/chatwoot/chatwoot/deployment/chatwoot-worker.1.service /etc/systemd/system/chatwoot-worker.1.service
cp /home/chatwoot/chatwoot/deployment/chatwoot.target /etc/systemd/system/chatwoot.target

systemctl enable chatwoot.target
systemctl start chatwoot.target

read -p 'Would you like to configure Webserver and SSL (yes or no): ' configure_webserver

if [ $configure_webserver != "yes" ]
then
echo "Woot! Woot!! Chatwoot server installation is complete"
echo "The server will be accessible at http://<server-ip>:3000"
echo "To configure a domain and SSL certificate, follow the guide at https://www.chatwoot.com/docs/deployment/deploy-chatwoot-in-linux-vm"
else
read -p 'What is your domain name server (chatwoot.domain.com for example) : ' domain_name
curl https://ssl-config.mozilla.org/ffdhe4096.txt >> /etc/ssl/dhparam
wget https://raw.githubusercontent.com/chatwoot/chatwoot/develop/deployment/nginx_chatwoot.conf
cp nginx_chatwoot.conf /etc/nginx/sites-available/nginx_chatwoot.conf
certbot certonly --nginx -d $domain_name
sed -i "s/chatwoot.domain.com/$domain_name/g" /etc/nginx/sites-available/nginx_chatwoot.conf
ln -s /etc/nginx/sites-available/nginx_chatwoot.conf /etc/nginx/sites-enabled/nginx_chatwoot.conf
systemctl restart nginx
sudo -i -u chatwoot << EOF
cd chatwoot
sed -i "s/http:\/\/0.0.0.0:3000/https:\/\/$domain_name/g" .env
EOF
systemctl restart chatwoot.target
echo "Woot! Woot!! Chatwoot server installation is complete"
echo "The server will be accessible at https://$domain_name"
fi
