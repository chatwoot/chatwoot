#!/usr/bin/env bash

# Description: Chatwoot installation script
# OS: Ubuntu 20.04 LTS
# Script Version: 2.0.4
# Run this script as root

set -eu -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo '`getopt --test` failed in this environment.'
    exit 1
fi

# option --output/-o requires 1 argument
LONGOPTS=console,debug,help,install:,logs:,ssl,upgrade,webserver,version
OPTIONS=cdhi:l:suwv
CWCTL_VERSION="2.0.4"

# if user does not specify an option
if [ -z "$1" ]
then
  echo "No options specified. Use --help to learn more."
  exit 1
fi

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

c=n d=n h=n i=n l=n s=n u=n w=n v=n BRANCH=master SERVICE=web
# Iterate options in order and nicely split until we see --
while true; do
    case "$1" in
        -c|--console)
            c=y
            break
            ;;
        -d|--debug)
            d=y
            break
            ;;
        -h|--help)
            h=y
            break
            ;;
        -i|--install)
            i=y
            BRANCH="$2"
            break
            ;;
        -l|--logs)
            l=y
            SERVICE="$2"
            break
            ;;
        -s|--ssl)
            s=y
            shift
            ;;
        -u|--upgrade)
            u=y
            break
            ;;
        -w|--webserver)
            w=y
            shift
            ;;
        -v|--version)
            v=y
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Invalid option(s) specified. Use help(-h) to learn more."
            exit 3
            ;;
    esac
done

if [ "$d" == "y" ]; then
  echo "console: $c, debug: $d, help: $h, install: $i, BRANCH: $BRANCH, \
  logs: $l, SERVICE: $SERVICE, ssl: $s, upgrade: $u, webserver: $w"
fi

trap exit_handler EXIT
pg_pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15 ; echo '')

function exit_handler() {
  if [ "$?" -ne 0 ]; then
   echo -en "\nSome error has occured. Check '/var/log/chatwoot-setup.log' for details.\n"
   exit 1
  fi
}

if [ "$(id -u)" -ne 0 ]; then
  echo 'This script should be run as root.' >&2
  exit 1
fi

function get_domain_info() {
  read -rp 'Enter the domain/subdomain for Chatwoot (e.g., chatwoot.domain.com): ' domain_name
  read -rp 'Enter an email address for LetsEncrypt to send reminders when your SSL certificate is up for renewal: ' le_email
  cat << EOF

This script will generate SSL certificates via LetsEncrypt and serve Chatwoot at
https://$domain_name. Proceed further once you have pointed your DNS to the IP of the instance.

EOF
  read -rp 'Do you wish to proceed? (yes or no): ' exit_true
  if [ "$exit_true" == "no" ]
  then
    exit 1
  fi
}

function install_dependencies() {
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
      postgresql-client redis-tools \
      nodejs yarn patch ruby-dev zlib1g-dev liblzma-dev \
      libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev sudo
}

function install_databases() {
  apt install -y postgresql postgresql-contrib redis-server
}

function install_webserver() {
  apt install -y nginx nginx-full certbot python3-certbot-nginx
}

function create_cw_user() {
  if ! id -u "chatwoot"
  then
    adduser --disabled-login --gecos "" chatwoot
  fi
}

function configure_rvm() {
  create_cw_user

  gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable
  adduser chatwoot rvm
}

function configure_db() {
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

}

function setup_chatwoot() {
  secret=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 63 ; echo '')
  RAILS_ENV=production

  sudo -i -u chatwoot << EOF
  rvm --version
  rvm autolibs disable
  rvm install "ruby-3.0.4"
  rvm use 3.0.4 --default

  git clone https://github.com/chatwoot/chatwoot.git
  cd chatwoot
  git checkout "$BRANCH"
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

}


function run_db_migrations(){
  sudo -i -u chatwoot << EOF
  cd chatwoot
  RAILS_ENV=production bundle exec rails db:chatwoot_prepare
EOF

}

function configure_systemd_services() {
  cp /home/chatwoot/chatwoot/deployment/chatwoot-web.1.service /etc/systemd/system/chatwoot-web.1.service
  cp /home/chatwoot/chatwoot/deployment/chatwoot-worker.1.service /etc/systemd/system/chatwoot-worker.1.service
  cp /home/chatwoot/chatwoot/deployment/chatwoot.target /etc/systemd/system/chatwoot.target

  cp /home/chatwoot/chatwoot/deployment/chatwoot /etc/sudoers.d/chatwoot
  cp /home/chatwoot/chatwoot/deployment/setup_20.04.sh /usr/local/bin/cwctl
  chmod +x /usr/local/bin/cwctl

  systemctl enable chatwoot.target
  systemctl start chatwoot.target
}

function setup_ssl() {
  echo "debug: setting up ssl"
  echo "debug: domain: $domain_name"
  echo "debug: letsencrypt email: $le_email"
  curl https://ssl-config.mozilla.org/ffdhe4096.txt >> /etc/ssl/dhparam
  wget https://raw.githubusercontent.com/chatwoot/chatwoot/develop/deployment/nginx_chatwoot.conf
  cp nginx_chatwoot.conf /etc/nginx/sites-available/nginx_chatwoot.conf
  certbot certonly --non-interactive --agree-tos --nginx -m "$le_email" -d "$domain_name"
  sed -i "s/chatwoot.domain.com/$domain_name/g" /etc/nginx/sites-available/nginx_chatwoot.conf
  ln -s /etc/nginx/sites-available/nginx_chatwoot.conf /etc/nginx/sites-enabled/nginx_chatwoot.conf
  systemctl restart nginx
  sudo -i -u chatwoot << EOF
  cd chatwoot
  sed -i "s/http:\/\/0.0.0.0:3000/https:\/\/$domain_name/g" .env
EOF
  systemctl restart chatwoot.target
}

function setup_logging() {
  touch /var/log/chatwoot-setup.log
  LOG_FILE="/var/log/chatwoot-setup.log"
}

function ssl_success_message() {
    cat << EOF

***************************************************************************
Woot! Woot!! Chatwoot server installation is complete.
The server will be accessible at https://$domain_name

Join the community at https://chatwoot.com/community
***************************************************************************
EOF
}

function install() {

  cat << EOF

***************************************************************************
              Chatwoot Installation (latest)
***************************************************************************

For more verbose logs, open up a second terminal and follow along using,
'tail -f /var/log/chatwoot-setup.log'.

EOF

  sleep 3
  read -rp 'Would you like to configure a domain and SSL for Chatwoot?(yes or no): ' configure_webserver

  if [ "$configure_webserver" == "yes" ]
  then
    get_domain_info
  fi

  echo -en "\n"
  read -rp 'Would you like to install Postgres and Redis? (Answer no if you plan to use external services): ' install_pg_redis

  echo -en "\n➥ 1/9 Installing dependencies. This takes a while.\n"
  install_dependencies &>> "${LOG_FILE}"

  if [ "$install_pg_redis" != "no" ]
  then
    echo "➥ 2/9 Installing databases."
    install_databases &>> "${LOG_FILE}"
  else
    echo "➥ 2/9 Skipping Postgres and Redis installation."
  fi

  if [ "$configure_webserver" == "yes" ]
  then
    echo "➥ 3/9 Installing webserver."
    install_webserver &>> "${LOG_FILE}"
  else
    echo "➥ 3/9 Skipping webserver installation."
  fi

  echo "➥ 4/9 Setting up Ruby"
  configure_rvm &>> "${LOG_FILE}"

  if [ "$install_pg_redis" != "no" ]
  then
    echo "➥ 5/9 Setting up the database."
    configure_db &>> "${LOG_FILE}"
  else
    echo "➥ 5/9 Skipping database setup."
  fi

  echo "➥ 6/9 Installing Chatwoot. This takes a long while."
  setup_chatwoot &>> "${LOG_FILE}"

  if [ "$install_pg_redis" != "no" ]
  then
    echo "➥ 7/9 Running database migrations."
    run_db_migrations &>> "${LOG_FILE}"
  else
    echo "➥ 7/9 Skipping database migrations."
  fi

  echo "➥ 8/9 Setting up systemd services."
  configure_systemd_services &>> "${LOG_FILE}"

  public_ip=$(curl http://checkip.amazonaws.com -s)

  if [ "$configure_webserver" != "yes" ]
  then
    cat << EOF
➥ 9/9 Skipping SSL/TLS setup.

***************************************************************************
Woot! Woot!! Chatwoot server installation is complete.
The server will be accessible at http://$public_ip:3000

To configure a domain and SSL certificate, follow the guide at
https://www.chatwoot.com/docs/deployment/deploy-chatwoot-in-linux-vm

Join the community at https://chatwoot.com/community
***************************************************************************
EOF
  else
    echo "➥ 9/9 Setting up SSL/TLS."
    setup_ssl &>> "${LOG_FILE}"
    ssl_success_message
  fi

  if [ "$install_pg_redis" == "no" ]
  then
cat <<EOF

***************************************************************************
The database migrations had not run as Postgres and Redis were not installed
as part of the installation process. After modifying the environment
variables (in the .env file) with your external database credentials, run
the database migrations using the below command.
'RAILS_ENV=production bundle exec rails db:chatwoot_prepare'.
***************************************************************************
EOF
  fi

exit 0

}

function get_console() {
  sudo -i -u chatwoot bash -c " cd chatwoot && RAILS_ENV=production bundle exec rails c"
}

function help() {

  cat <<EOF
Usage: cwctl [OPTION]...
Install and manage your Chatwoot installation.

Example: cwctl -i master
Example: cwctl -l web
Example: cwctl --logs worker
Example: cwctl --upgrade
Example: cwctl -c

Installation/Upgrade:
  -i, --install             install Chatwoot with the git branch specified
  -u, --upgrade             upgrade Chatwoot to latest version
  -s, --ssl                 fetch and install ssl certificates using LetsEncrypt
  -w, --webserver           install and configure Nginx webserver with SSL

Management:
  -c, --console             open ruby console
  -l, --logs                view logs from Chatwoot. Supported values include web/worker.
  
Miscellaneous:
  -d, --debug               show debug messages
  -v, --version             display version information and exit
  -h, --help                display this help text and exit

Exit status:
Returns 0 if successful; non-zero otherwise.

Report bugs at https://github.com/chatwoot/chatwoot/issues
Get help, https://chatwoot.com/community

EOF
}

function get_logs() {
  if [ "$SERVICE" == "worker" ]
  then
    journalctl -u chatwoot-worker.1.service -f
  else
    journalctl -u chatwoot-web.1.service -f
  fi
}

function ssl() {
   echo "Setting up ssl"
   get_domain_info
   if ! systemctl -q is-active nginx; then
    install_webserver
   fi
   setup_ssl
   ssl_success_message
}

function upgrade() {
  echo "Upgrading Chatwoot to latest version"

  sudo -i -u chatwoot << "EOF"

  # Navigate to the Chatwoot directory
  cd chatwoot

  # Pull the latest version of the master branch
  git checkout master && git pull

  # Ensure the ruby version is upto date
  # Parse the latest ruby version
  latest_ruby_version="$(cat '.ruby-version')"
  rvm install "ruby-$latest_ruby_version"
  rvm use "$latest_ruby_version" --default

  # Update dependencies
  bundle
  yarn

  # Recompile the assets
  rake assets:precompile RAILS_ENV=production

  # Migrate the database schema
  RAILS_ENV=production bundle exec rake db:migrate

EOF

  # Copy the updated targets
  cp /home/chatwoot/chatwoot/deployment/chatwoot-web.1.service /etc/systemd/system/chatwoot-web.1.service
  cp /home/chatwoot/chatwoot/deployment/chatwoot-worker.1.service /etc/systemd/system/chatwoot-worker.1.service
  cp /home/chatwoot/chatwoot/deployment/chatwoot.target /etc/systemd/system/chatwoot.target

  cp /home/chatwoot/chatwoot/deployment/chatwoot /etc/sudoers.d/chatwoot
  # TODO:(@vn) handle cwctl updates
  #cp /home/chatwoot/chatwoot/deployment/setup_20.04.sh /usr/local/bin/cwctl
  #chmod +x /usr/local/bin/cwctl

  systemctl daemon-reload

  # Restart the chatwoot server
  systemctl restart chatwoot.target

}

function webserver() {
  echo "Installing nginx"
  ssl
  #TODO: allow installing nginx only without SSL
}

function version() {
  echo "cwctl v$CWCTL_VERSION alpha build"
}

function main() {
  setup_logging

  if [ "$c" == "y" ]
  then
    get_console
  fi
  
  if [ "$h" == "y" ]
  then
    help
  fi

  if [ "$i" == "y" ]
  then
    install
  fi

  if [ "$l" == "y" ]
  then
    get_logs
  fi
  
  if [ "$s" == "y" ]
  then
    ssl
  fi

  if [ "$u" == "y" ]
  then
    upgrade
  fi

  if [ "$w" == "y" ]
  then
    webserver
  fi

  if [ "$v" == "y" ]
  then
    version
  fi

}

main "$@"
