---redis
sudo add-apt-repository ppa:redislabs/redis
sudo apt-get update
sudo apt-get install redis
------

gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys \
409B6B1796C275462A1703113804BB82D39DC0E3 \
7D2BAF1CF37B13E2069D6956105BD0E739499BDB


/bin/bash --login

\curl -sSL https://get.rvm.io | bash -s stable

rvm install ruby-3.4.4
rvm use ruby-3.4.4 --default


db setup
------------
set postgres to localhost
set username and password
need to install postgresql-14-pgvector

instructions:
sudo apt install curl ca-certificates gnupg lsb-release
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt install postgresql-14-pgvector
sudo service postgresql restart


for newer version of rails 7.1+ in enhancements rake
replace 
db_namespace['load_config'].invoke if ActiveRecord::Base.connection.schema_format == :ruby
with
db_namespace['load_config'].invoke if Rails.application.config.active_record.schema_format == :ruby


update redis server to redis://localhost:6379

/// if not able to login run
RAILS_ENV=development bundle exec rails db:seed
------------------


update procfile test

vite: node --experimental-global-webcrypto ./node_modules/.bin/vite dev 
pnpm add -D postcss postcss-import postcss-loader

pnpm install --save-dev cypress

pnpm exec cypress install


