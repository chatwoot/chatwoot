#!/usr/bin/env bash

# Description: Chatwoot installation script
# OS: Ubuntu 20.04 LTS / Ubuntu 20.10
# Script Version: 0.7
# Run this script as root

read -p 'Would you like to configure a domain and SSL for Chatwoot?(yes or no): ' configure_webserver

if [ $configure_webserver == "yes" ]
then
read -p 'Enter your sub-domain to be used for Chatwoot (chatwoot.domain.com for example) : ' domain_name
echo -e "\nThis script will try to generate SSL certificates via LetsEncrypt and serve chatwoot at
"https://$domain_name". Proceed further once you have pointed your DNS to the IP of the instance.\n"
read -p 'Do you wish to proceed? (yes or no): ' exit_true
if [ $exit_true == "no" ]
then
exit 1
fi
fi


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


if [ $configure_webserver == "yes" ]
then
apt install -y nginx nginx-full certbot python3-certbot-nginx
fi

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
echo -en "\nINSTALLATION_ENV=linux_script" >> ".env"

rake assets:precompile RAILS_ENV=production
EOF

if [ $install_pg_redis != "no" ]
then
sudo -i -u chatwoot << EOF
cd chatwoot
RAILS_ENV=production bundle exec rake db:create
RAILS_ENV=production bundle exec rake db:reset
EOF
fi

cp /home/chatwoot/chatwoot/deployment/chatwoot-web.1.service /etc/systemd/system/chatwoot-web.1.service
cp /home/chatwoot/chatwoot/deployment/chatwoot-worker.1.service /etc/systemd/system/chatwoot-worker.1.service
cp /home/chatwoot/chatwoot/deployment/chatwoot.target /etc/systemd/system/chatwoot.target

systemctl enable chatwoot.target
systemctl start chatwoot.target

public_ip=$(curl http://checkip.amazonaws.com -s)

if [ $configure_webserver != "yes" ]
then
echo -en "\n\n***************************************************************************\n"
echo "Woot! Woot!! Chatwoot server installation is complete"
echo "The server will be accessible at http://$public_ip:3000"
echo "To configure a domain and SSL certificate, follow the guide at https://www.chatwoot.com/docs/deployment/deploy-chatwoot-in-linux-vm"
echo "***************************************************************************"
else
curl https://ssl-config.mozilla.org/ffdhe4096.txt >> /etc/ssl/dhparam
wget https://raw.githubusercontent.com/shaulirep/rep-live-chat/develop/deployment/nginx_chatwoot.conf
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
echo -en "\n\n***************************************************************************\n"
echo "Woot! Woot!! Chatwoot server installation is complete"
echo "The server will be accessible at https://$domain_name"
echo "***************************************************************************"
fi


if [ $install_pg_redis == "no" ]
then
echo -en "\n\n***************************************************************************\n"
echo "DB migrations are not run as pg and redis is not installed."
echo "After modifying .env with your external db creds, run db migrations !!!"
echo "***************************************************************************"
fi
