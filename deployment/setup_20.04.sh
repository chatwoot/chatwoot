#!/usr/bin/env bash

# Description: Chatwoot installation script
# OS: Ubuntu 20.04 LTS / Ubuntu 20.10
# Script Version: 0.7
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
    libssl-dev libyaml-dev libreadline-dev gnupg2 \
    nodejs yarn patch ruby-dev zlib1g-dev liblzma-dev \
    libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev



adduser --disabled-login --gecos "" chatwoot

gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
adduser chatwoot rvm


secret=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 63 ; echo '')
RAILS_ENV=production

sudo -i -u chatwoot << EOF
rvm --version
rvm autolibs disable
rvm install "ruby-3.0.2"
rvm use 3.0.2 --default

git clone https://github.com/shaulirep/rep-live-chat.git
cd /home/chatwoot/rep-live-chat
if [[ -z "$1" ]]; then
git checkout master;
else
git checkout $1;
fi
bundle
yarn

cp /home/chatwoot/rep-live-chat/.env.example .env
sed -i -e "/SECRET_KEY_BASE/ s/=.*/=$secret/" .env
sed -i -e '/REDIS_URL/ s/=.*/=redis:\/\/localhost:6379/' .env
sed -i -e '/POSTGRES_HOST/ s/=.*/=localhost/' .env
sed -i -e '/POSTGRES_USERNAME/ s/=.*/=chatwoot/' .env
sed -i -e "/POSTGRES_PASSWORD/ s/=.*/=$pg_pass/" .env
sed -i -e '/RAILS_ENV/ s/=.*/=$RAILS_ENV/' .env
echo -en "\nINSTALLATION_ENV=linux_script" >> ".env"

gem install bundler:2.2.25
rake assets:precompile RAILS_ENV=production
EOF


cp /home/chatwoot/rep-live-chat/deployment/chatwoot-web.1.service /etc/systemd/system/chatwoot-web.1.service
cp /home/chatwoot/rep-live-chat/deployment/chatwoot-worker.1.service /etc/systemd/system/chatwoot-worker.1.service
cp /home/chatwoot/rep-live-chat/deployment/chatwoot.target /etc/systemd/system/chatwoot.target

systemctl enable chatwoot.target
systemctl start chatwoot.target

public_ip=$(curl http://checkip.amazonaws.com -s)


echo -en "\n\n***************************************************************************\n"
echo "Woot! Woot!! Chatwoot server installation is complete"
echo "The server will be accessible at http://$public_ip:3000"
echo "To configure a domain and SSL certificate, follow the guide at https://www.chatwoot.com/docs/deployment/deploy-chatwoot-in-linux-vm"
echo "***************************************************************************"


echo -en "\n\n***************************************************************************\n"
echo "DB migrations are not run as pg and redis is not installed."
echo "After modifying .env with your external db creds, run db migrations !!!"
echo "***************************************************************************"
