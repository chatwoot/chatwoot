#!/usr/bin/env bash

#description: chatwoot installation script
#OS: Ubuntu 18.04 LTS
#script_version: 0.1

apt update && apt upgrade -y
apt install -y curl
curl -sL https://deb.nodesource.com/setup_12.x | bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt update

apt install -y \
	git-core software-properties-common imagemagick libpq-dev \
    libxml2-dev libxslt1-dev file g++ gcc autoconf build-essential \
    libssl-dev libyaml-dev libreadline6-dev gnupg2 nginx redis-server \
    redis-tools postgresql postgresql-contrib certbot \
    python-certbot-nginx yarn patch ruby-dev zlib1g-dev liblzma-dev \
    libgmp-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev


adduser --disabled-login --gecos "" chatwoot

sudo -i -u chatwoot bash << EOF
whoami
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
EOF

pg_pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15 ; echo '')
sudo -i -u postgres psql << EOF
\set pass `echo $pg_pass`
CREATE USER chatwoot CREATEDB;
ALTER USER chatwoot PASSWORD :'pass';
EOF

systemctl enable redis-server.service
systemctl enable postgresql

secret=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 63 ; echo '')
RAILS_ENV=production

# sudo -i -u chatwoot << EOF
# git clone https://github.com/rbenv/rbenv.git ~/.rbenv
# echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
# echo 'eval "$(rbenv init -)"' >> ~/.bashrc
# git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
# echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
# git clone https://github.com/rbenv/rbenv-vars.git ~/.rbenv/plugins/rbenv-vars
# EOF

sudo -i -u chatwoot << EOF
# rbenv install 2.7.0
# rbenv global 2.7.0
# gem install bundler
# gem install procsd

rvm --version
rvm autolibs disable
rvm install "ruby-2.7.0"
rvm use 2.7.0 --default

git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot
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
RAILS_ENV=production foreman start -f Procfile
EOF

#TODO: systemd
#TODO: nginx


