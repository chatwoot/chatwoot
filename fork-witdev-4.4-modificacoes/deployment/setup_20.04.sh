#!/usr/bin/env bash

# Description: Install and manage a Chatwoot installation.
# OS: Ubuntu 20.04 LTS, 22.04 LTS, 24.04 LTS
# Script Version: 3.2.0
# Run this script as root

set -eu -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo '`getopt --test` failed in this environment.'
    exit 1
fi

# Global variables
# option --output/-o requires 1 argument
LONGOPTS=console,debug,help,install,Install:,logs:,restart,ssl,upgrade,webserver,version
OPTIONS=cdhiI:l:rsuwv
CWCTL_VERSION="3.2.0"
pg_pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15 ; echo '')
CHATWOOT_HUB_URL="https://hub.2.chatwoot.com/events"

# if user does not specify an option
if [ "$#" -eq 0 ]; then
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

c=n d=n h=n i=n I=n l=n r=n s=n u=n w=n v=n BRANCH=master SERVICE=web
# Iterate options in order and nicely split until we see --
while true; do
    case "$1" in
        -c|--console)
            c=y
            break
            ;;
        -d|--debug)
            d=y
            shift
            ;;
        -h|--help)
            h=y
            break
            ;;
        -i|--install)
            i=y
            BRANCH="master"
            break
            ;;
       -I|--Install)
            I=y
            BRANCH="$2"
            break
            ;;
        -l|--logs)
            l=y
            SERVICE="$2"
            break
            ;;
        -r|--restart)
            r=y
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

# log if debug flag set
if [ "$d" == "y" ]; then
  echo "console: $c, debug: $d, help: $h, install: $i, Install: $I, BRANCH: $BRANCH, \
  logs: $l, SERVICE: $SERVICE, ssl: $s, upgrade: $u, webserver: $w"
fi

# exit if script is not run as root
if [ "$(id -u)" -ne 0 ]; then
  echo 'This needs to be run as root.' >&2
  exit 1
fi

trap exit_handler EXIT

##############################################################################
# Invoked upon EXIT signal from bash
# Upon non-zero exit, notifies the user to check log file.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function exit_handler() {
  if [ "$?" -ne 0 ] && [ "$u" == "n" ]; then
   echo -en "\nSome error has occured. Check '/var/log/chatwoot-setup.log' for details.\n"
   exit 1
  fi
}

##############################################################################
# Read user input related to domain setup
# Globals:
#   domain_name
#   le_email
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function get_domain_info() {
  read -rp 'Enter the domain/subdomain for Chatwoot (e.g., chatwoot.domain.com): ' domain_name
  read -rp 'Enter an email address for LetsEncrypt to send reminders when your SSL certificate is up for renewal: ' le_email
  cat << EOF

This script will generate SSL certificates via LetsEncrypt and
serve Chatwoot at https://$domain_name.
Proceed further once you have pointed your DNS to the IP of the instance.

EOF
  read -rp 'Do you wish to proceed? (yes or no): ' exit_true
  if [ "$exit_true" == "no" ]; then
    exit 1
  fi
}

##############################################################################
# Install common dependencies
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function install_dependencies() {
  apt-get update && apt-get upgrade -y
  apt-get install -y curl
  curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  NODE_MAJOR=23
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg 16" > /etc/apt/sources.list.d/pgdg.list
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -


  apt-get update

  apt-get install -y \
      git software-properties-common ca-certificates imagemagick libpq-dev \
      libxml2-dev libxslt1-dev file g++ gcc autoconf build-essential \
      libssl-dev libyaml-dev libreadline-dev gnupg2 \
      postgresql-client-16 redis-tools \
      nodejs patch ruby-dev zlib1g-dev liblzma-dev \
      libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev sudo \
      libvips python3-pip
  npm install -g pnpm
}

##############################################################################
# Install postgres and redis
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function install_databases() {
  apt-get install -y postgresql-16 postgresql-16-pgvector postgresql-contrib redis-server
}

##############################################################################
# Install nginx and cerbot for LetsEncrypt
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function install_webserver() {
  apt-get install -y nginx nginx-full certbot python3-certbot-nginx
}

##############################################################################
# Create chatwoot linux user
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function create_cw_user() {
  if ! id -u "chatwoot"; then
    adduser --disabled-password --gecos "" chatwoot
  fi
}

##############################################################################
# Install rvm(ruby version manager)
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function configure_rvm() {
  create_cw_user

  gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable
  adduser chatwoot rvm
}

##############################################################################
# Save the pgpass used to setup postgres
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function save_pgpass() {
  mkdir -p /opt/chatwoot/config
  file="/opt/chatwoot/config/.pg_pass"
  if ! test -f "$file"; then
    echo $pg_pass > /opt/chatwoot/config/.pg_pass
  fi
}

##############################################################################
# Get the pgpass used to setup postgres if installation fails midway
# and needs to be re-run
# Globals:
#   pg_pass
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function get_pgpass() {
  file="/opt/chatwoot/config/.pg_pass"
  if test -f "$file"; then
    pg_pass=$(cat $file)
  fi

}

##############################################################################
# Configure postgres to create chatwoot db user.
# Enable postgres and redis systemd services.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function configure_db() {
  save_pgpass
  get_pgpass
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

##############################################################################
# Install Chatwoot
# This includes setting up ruby, cloning repo and installing dependencies.
# Globals:
#   pg_pass
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function setup_chatwoot() {
  local secret=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 63 ; echo '')
  local RAILS_ENV=production
  get_pgpass

  sudo -i -u chatwoot << EOF
  rvm --version
  rvm autolibs disable
  rvm install "ruby-3.4.4"
  rvm use 3.4.4 --default

  git clone https://github.com/chatwoot/chatwoot.git
  cd chatwoot
  git checkout "$BRANCH"
  bundle
  pnpm i

  cp .env.example .env
  sed -i -e "/SECRET_KEY_BASE/ s/=.*/=$secret/" .env
  sed -i -e '/REDIS_URL/ s/=.*/=redis:\/\/localhost:6379/' .env
  sed -i -e '/POSTGRES_HOST/ s/=.*/=localhost/' .env
  sed -i -e '/POSTGRES_USERNAME/ s/=.*/=chatwoot/' .env
  sed -i -e "/POSTGRES_PASSWORD/ s/=.*/=$pg_pass/" .env
  sed -i -e '/RAILS_ENV/ s/=.*/=$RAILS_ENV/' .env
  echo -en "\nINSTALLATION_ENV=linux_script" >> ".env"

  rake assets:precompile RAILS_ENV=production NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider"
EOF
}

##############################################################################
# Run database migrations.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function run_db_migrations(){
  sudo -i -u chatwoot << EOF
  cd chatwoot
  RAILS_ENV=production POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare
EOF
}

##############################################################################
# Setup Chatwoot systemd services and cwctl CLI
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
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

##############################################################################
# Fetch and install SSL certificates from LetsEncrypt
# Modify the nginx config and restart nginx.
# Also modifies FRONTEND_URL in .env file.
# Globals:
#   None
# Arguments:
#   domain_name
#   le_email
# Outputs:
#   None
##############################################################################
function setup_ssl() {
  if [ "$d" == "y" ]; then
    echo "debug: setting up ssl"
    echo "debug: domain: $domain_name"
    echo "debug: letsencrypt email: $le_email"
  fi
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

##############################################################################
# Setup logging
# Globals:
#   LOG_FILE
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function setup_logging() {
  touch /var/log/chatwoot-setup.log
  LOG_FILE="/var/log/chatwoot-setup.log"
}

function ssl_success_message() {
    cat << EOF

***************************************************************************
Woot! Woot!! Chatwoot server installation is complete.
The server will be accessible at https://$domain_name

Join the community at https://chatwoot.com/community?utm_source=cwctl
***************************************************************************

EOF
}

function cwctl_message() {
  echo $'\U0001F680 Try out the all new Chatwoot CLI tool to manage your installation.'
  echo $'\U0001F680 Type "cwctl --help" to learn more.'
}


##############################################################################
# This function handles the installation(-i/--install)
# Globals:
#   CW_VERSION
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function get_cw_version() {
  CW_VERSION=$(curl -s https://app.chatwoot.com/api | python3 -c 'import sys,json;data=json.loads(sys.stdin.read()); print(data["version"])')
}

##############################################################################
# This function handles the installation(-i/--install)
# Globals:
#   configure_webserver
#   install_pg_redis
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function install() {
  get_cw_version
  cat << EOF

***************************************************************************
              Chatwoot Installation (v$CW_VERSION)
***************************************************************************

For more verbose logs, open up a second terminal and follow along using,
'tail -f /var/log/chatwoot-setup.log'.

EOF

  sleep 3
  read -rp 'Would you like to configure a domain and SSL for Chatwoot?(yes or no): ' configure_webserver

  if [ "$configure_webserver" == "yes" ]; then
    get_domain_info
  fi

  echo -en "\n"
  read -rp 'Would you like to install Postgres and Redis? (Answer no if you plan to use external services)(yes or no): ' install_pg_redis

  echo -en "\n➥ 1/9 Installing dependencies. This takes a while.\n"
  install_dependencies &>> "${LOG_FILE}"

  if [ "$install_pg_redis" != "no" ]; then
    echo "➥ 2/9 Installing databases."
    install_databases &>> "${LOG_FILE}"
  else
    echo "➥ 2/9 Skipping Postgres and Redis installation."
  fi

  if [ "$configure_webserver" == "yes" ]; then
    echo "➥ 3/9 Installing webserver."
    install_webserver &>> "${LOG_FILE}"
  else
    echo "➥ 3/9 Skipping webserver installation."
  fi

  echo "➥ 4/9 Setting up Ruby"
  configure_rvm &>> "${LOG_FILE}"

  if [ "$install_pg_redis" != "no" ]; then
    echo "➥ 5/9 Setting up the database."
    configure_db &>> "${LOG_FILE}"
  else
    echo "➥ 5/9 Skipping database setup."
  fi

  echo "➥ 6/9 Installing Chatwoot. This takes a long while."
  setup_chatwoot &>> "${LOG_FILE}"

  if [ "$install_pg_redis" != "no" ]; then
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
https://www.chatwoot.com/docs/deployment/deploy-chatwoot-in-linux-vm?utm_source=cwctl

Join the community at https://chatwoot.com/community?utm_source=cwctl
***************************************************************************

EOF
  cwctl_message
  else
    echo "➥ 9/9 Setting up SSL/TLS."
    setup_ssl &>> "${LOG_FILE}"
    ssl_success_message
    cwctl_message
  fi

  if [ "$install_pg_redis" == "no" ]
  then
cat <<EOF

***************************************************************************
The database migrations had not run as Postgres and Redis were not installed
as part of the installation process. After modifying the environment
variables (in the .env file) with your external database credentials, run
the database migrations using the below command.
'RAILS_ENV=production POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare'.
***************************************************************************

EOF
  cwctl_message
  fi

exit 0

}

##############################################################################
# Access ruby console (-c/--console)
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function get_console() {
  sudo -i -u chatwoot bash -c " cd chatwoot && RAILS_ENV=production bundle exec rails c"
}

##############################################################################
# Prints the help message (-c/--console)
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
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
  -i, --install             Install the latest stable version of Chatwoot
  -I                        Install Chatwoot from a git branch
  -u, --upgrade             Upgrade Chatwoot to the latest stable version
  -s, --ssl                 Fetch and install SSL certificates using LetsEncrypt
  -w, --webserver           Install and configure Nginx webserver with SSL

Management:
  -c, --console             Open ruby console
  -l, --logs                View logs from Chatwoot. Supported values include web/worker.
  -r, --restart             Restart Chatwoot server

Miscellaneous:
  -d, --debug               Show debug messages
  -v, --version             Display version information
  -h, --help                Display this help text

Exit status:
Returns 0 if successful; non-zero otherwise.

Report bugs at https://github.com/chatwoot/chatwoot/issues
Get help, https://chatwoot.com/community?utm_source=cwctl

EOF
}

##############################################################################
# Get Chatwoot web/worker logs (-l/--logs)
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function get_logs() {
  if [ "$SERVICE" == "worker" ]; then
    journalctl -u chatwoot-worker.1.service -f
  fi
  if [ "$SERVICE" == "web" ]; then
    journalctl -u chatwoot-web.1.service -f
  fi
}

##############################################################################
# Setup SSL (-s/--ssl)
# Installs nginx if not available.
# Globals:
#   domain_name
#   le_email
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function ssl() {
   if [ "$d" == "y" ]; then
     echo "Setting up ssl"
   fi
   get_domain_info
   if ! systemctl -q is-active nginx; then
    install_webserver
   fi
   setup_ssl
   ssl_success_message
}

##############################################################################
# Abort upgrade if custom code changes detected(-u/--upgrade)
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function upgrade_prereq() {
  sudo -i -u chatwoot << "EOF"
  cd chatwoot
  git update-index --refresh
  git diff-index --quiet HEAD --
  if [ "$?" -eq 1 ]; then
    echo "Custom code changes detected. Aborting update."
    echo "Please proceed to update manually."
    exit 1
  fi
EOF
}

##############################################################################
# Update redis to v7+ for Rails 7 support(-u/--upgrade)
# and install libvips for image processing support in Rails 7
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function upgrade_redis() {

  echo "Checking Redis availability..."

  # Check if Redis is installed
  if ! command -v redis-server &> /dev/null; then
    echo "Redis is not installed. Skipping Redis upgrade."
    return
  fi

  echo "Checking Redis version..."

  # Get current Redis version
  current_version=$(redis-server --version | awk -F 'v=' '{print $2}' | awk '{print $1}')

  # Parse major version number
  major_version=$(echo "$current_version" | cut -d. -f1)

  if [ "$major_version" -ge 7 ]; then
    echo "Redis is already version $current_version (>= 7). Skipping Redis upgrade."
    return
  fi

  echo "Upgrading Redis to v7+ for Rails 7 support(Chatwoot v2.17+)"

  curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
  apt-get update -y
  apt-get upgrade redis-server -y
  apt-get install libvips -y
}


##############################################################################
# Update nodejs to v20+
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function upgrade_node() {
  echo "Checking Node.js version..."

  # Get current Node.js version
  current_version=$(node --version | cut -c 2-)

  # Parse major version number
  major_version=$(echo "$current_version" | cut -d. -f1)

  if [ "$major_version" -ge 23 ]; then
    echo "Node.js is already version $current_version (>= 23.x). Skipping Node.js upgrade."
    return
  fi

  echo "Upgrading Node.js version to v23.x"
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  NODE_MAJOR=23
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

  apt-get update
  apt-get install nodejs -y

}

##############################################################################
# Install pnpm - this replaces yarn starting from Chatwoot 4.0
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function get_pnpm() {
  # if pnpm is already installed, return
  if command -v pnpm &> /dev/null; then
    echo "pnpm is already installed. Skipping installation."
    return
  fi
  echo "pnpm is not installed. Installing pnpm..."
  npm install -g pnpm
  echo "Cleaning up existing node_modules directory..."
  sudo -i -u chatwoot << "EOF"
  cd chatwoot
  rm -rf node_modules
EOF
}

##############################################################################
# Upgrade an existing installation to latest stable version(-u/--upgrade)
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function upgrade() {
  cwctl_upgrade_check
  get_cw_version
  echo "Upgrading Chatwoot to v$CW_VERSION"
  sleep 3

   # Check if CW_VERSION is 4.0 or above
  if [[ "$(printf '%s\n' "$CW_VERSION" "4.0" | sort -V | head -n 1)" == "4.0" ]]; then
    echo "Chatwoot v4.0 and above requires pgvector support in PostgreSQL."
    read -p "Does your postgres support pgvector and want to proceed with the upgrade? [Y/n]: " user_input
    user_input=${user_input:-Y}
    if [[ "$user_input" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "Proceeding with the upgrade..."
    else
      echo "Upgrade aborted. Please install pgvector support before upgrading."
      echo "Read more at https://chwt.app/v4/migration"
      return 1
    fi
  fi

  upgrade_prereq
  upgrade_redis
  upgrade_node
  get_pnpm
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
  pnpm i

  # Recompile the assets
  rake assets:precompile RAILS_ENV=production NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider"

  # Migrate the database schema
  RAILS_ENV=production POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rake db:migrate

EOF

  # Copy the updated targets
  cp /home/chatwoot/chatwoot/deployment/chatwoot-web.1.service /etc/systemd/system/chatwoot-web.1.service
  cp /home/chatwoot/chatwoot/deployment/chatwoot-worker.1.service /etc/systemd/system/chatwoot-worker.1.service
  cp /home/chatwoot/chatwoot/deployment/chatwoot.target /etc/systemd/system/chatwoot.target

  cp /home/chatwoot/chatwoot/deployment/chatwoot /etc/sudoers.d/chatwoot
  # TODO:(@vn) handle cwctl updates

  systemctl daemon-reload

  # Restart the chatwoot server
  systemctl restart chatwoot.target

}

##############################################################################
# Restart Chatwoot server (-r/--restart)
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function restart() {
  systemctl restart chatwoot.target
  systemctl status chatwoot.target
}

##############################################################################
# Install nginx and setup SSL (-w/--webserver)
# Globals:
#   domain_name
#   le_email
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function webserver() {
  if [ "$d" == "y" ]; then
     echo "Installing nginx"
  fi
  ssl
  #TODO(@vn): allow installing nginx only without SSL
}


##############################################################################
# Report cwctl events to hub
# Globals:
#   CHATWOOT_HUB_URL
# Arguments:
# event_name: Name of the event to report
# event_data: Data to report
# installation_identifier: Installation identifier
# Outputs:
#   None
##############################################################################
function report_event() {
  local event_name="$1"
  local event_data="$2"

  CHATWOOT_HUB_URL="https://hub.2.chatwoot.com/events"

  # get installation identifier
  local installation_identifier=$(get_installation_identifier)

  # Prepare the data for the request
  local data="{\"installation_identifier\":\"$installation_identifier\",\"event_name\":\"$event_name\",\"event_data\":{\"action\":\"$event_data\"}}"

  # Make the curl request to report the event
  curl -X POST -H "Content-Type: application/json" -d "$data" "$CHATWOOT_HUB_URL" -s -o /dev/null
}


##############################################################################
# Get installation identifier
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   installation_identifier
##############################################################################
function get_installation_identifier() {

  local installation_identifier

  installation_identifier=$(sudo -i -u chatwoot << "EOF"
  cd chatwoot
  RAILS_ENV=production bundle exec rake instance_id:get_installation_identifier
EOF
)
  echo "$installation_identifier"
}

##############################################################################
# Print cwctl version (-v/--version)
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function version() {
  echo "cwctl v$CWCTL_VERSION"
}

##############################################################################
# Check if there is newer version of cwctl and upgrade if found
# Globals:
#   CWCTL_VERSION
# Arguments:
# remote_version_url = URL to fetch the remote version from
# remote_version = Remote version of cwctl
# Outputs:
#   None
##############################################################################
function cwctl_upgrade_check() {
    echo "Checking for cwctl updates..."

    local remote_version_url="https://raw.githubusercontent.com/chatwoot/chatwoot/master/VERSION_CWCTL"
    local remote_version=$(curl -s "$remote_version_url")

    #Check if pip is not installed, and install it if not
    if ! command -v pip3 &> /dev/null; then
        echo "Installing pip..."
        apt-get install -y python3-pip
    fi

    # Check if packaging library is installed, and install it if not
    if ! python3 -c "import packaging.version" &> /dev/null; then
        echo "Installing packaging library..."
        install_packaging
    fi

    needs_update=$(python3 -c "from packaging import version; v1 = version.parse('$CWCTL_VERSION'); v2 = version.parse('$remote_version'); print(1 if v2 > v1 else 0)")

    if [ "$needs_update" -eq 1 ]; then
        echo "Upgrading cwctl from $CWCTL_VERSION to $remote_version"
        upgrade_cwctl
        echo $'\U0002713 Done'
        echo $'\U0001F680 Please re-run your command'
        exit 0
    else
        echo "Your cwctl is up to date"
    fi

}

##############################################################################
# Check for PEP 668 restrictions and install packaging accordingly
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function install_packaging() {
  ubuntu_version=$(lsb_release -r | awk '{print $2}')
  if [[ "$ubuntu_version" == "24.04" ]]; then
    echo "Detected Ubuntu 24.04. Installing packaging library using apt."
    apt-get install -y python3-packaging
  else
    echo "Installing packaging library using pip."
    python3 -m pip install packaging
  fi
}



##############################################################################
# upgrade cwctl
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function upgrade_cwctl() {
    wget https://get.chatwoot.app/linux/install.sh -O /usr/local/bin/cwctl > /dev/null 2>&1 && chmod +x /usr/local/bin/cwctl
}

##############################################################################
# main function that handles the control flow
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
##############################################################################
function main() {
  setup_logging

  if [ "$c" == "y" ]; then
    report_event "cwctl" "console" > /dev/null 2>&1
    get_console
  fi

  if [ "$h" == "y" ]; then
    report_event "cwctl" "help"  > /dev/null 2>&1
    help
  fi

  if [ "$i" == "y" ] || [ "$I" == "y" ]; then
    install
    report_event "cwctl" "install"  > /dev/null 2>&1
  fi

  if [ "$l" == "y" ]; then
    report_event "cwctl" "logs"  > /dev/null 2>&1
    get_logs
  fi

  if [ "$r" == "y" ]; then
    report_event "cwctl" "restart"  > /dev/null 2>&1
    restart
  fi

  if [ "$s" == "y" ]; then
    report_event "cwctl" "ssl"  > /dev/null 2>&1
    ssl
  fi

  if [ "$u" == "y" ]; then
    report_event "cwctl" "upgrade"  > /dev/null 2>&1
    upgrade
  fi

  if [ "$w" == "y" ]; then
    report_event "cwctl" "webserver"  > /dev/null 2>&1
    webserver
  fi

  if [ "$v" == "y" ]; then
    report_event "cwctl" "version"  > /dev/null 2>&1
    version
  fi

}

main "$@"
