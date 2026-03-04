Self-Hosted Installation Guide
Complete guide to install and setup a production-ready Chatwoot instance on your own infrastructure.

Welcome to the Chatwoot self-hosted installation guide. This comprehensive documentation will help you deploy, configure, and maintain your own Chatwoot instance with full control over your data and infrastructure.
​
Why Self-Host Chatwoot?
Self-hosting Chatwoot gives you complete control over your customer support platform:
Data Privacy: Keep all customer data on your own servers
Customization: Modify the platform to fit your specific needs
Cost Control: No per-agent pricing - scale as much as you need
Compliance: Meet specific regulatory requirements
Integration: Deep integration with your existing infrastructure
​
Deployment Options
Chatwoot supports multiple deployment methods to fit different infrastructure needs:
​
🐧 Linux VM Deployment
Deploy directly on Ubuntu/Linux virtual machines with our automated installation script.
Best for: Traditional server environments
Complexity: Low to Medium
Maintenance: Manual updates required
​
🐳 Docker Deployment
Use Docker containers for consistent, portable deployments.
Best for: Containerized environments
Complexity: Medium
Maintenance: Easy updates with container pulls
​
☸️ Kubernetes Deployment
Deploy on Kubernetes clusters for enterprise-scale operations.
Best for: Large-scale, high-availability deployments
Complexity: High
Maintenance: Automated with proper CI/CD
​
☁️ Cloud Provider Deployments
One-click deployments on major cloud platforms:
AWS: EC2, ECS, and Marketplace options
Azure: Container Instances and VM deployments
DigitalOcean: Droplets and App Platform
Google Cloud: Compute Engine and Cloud Run
Heroku: Simple one-click deployment
​
System Requirements
​
Minimum Requirements
CPU: 2 cores
RAM: 4GB
Storage: 20GB SSD
OS: Ubuntu 20.04+ or compatible Linux distribution
​
Recommended for Production
CPU: 4+ cores
RAM: 8GB+
Storage: 50GB+ SSD
Database: PostgreSQL 12+
Cache: Redis 6+
Reverse Proxy: Nginx or similar
​
What You’ll Need
Before starting your Chatwoot installation, ensure you have:
​
Technical Requirements
 Server or cloud instance meeting minimum requirements
 Domain name (recommended for production)
 SSL certificate (Let’s Encrypt recommended)
 SMTP server for email notifications
​
Access Requirements
 SSH access to your server
 Root or sudo privileges
 Firewall configuration access
​
Optional but Recommended
 Object storage (AWS S3, Google Cloud Storage, etc.)
 CDN for static assets
 Monitoring tools (APM, logging)
 Backup solution
​
Security Considerations
When self-hosting Chatwoot, consider these security aspects:
Regular Updates: Keep Chatwoot and system packages updated
Firewall Configuration: Only expose necessary ports
SSL/TLS: Always use HTTPS in production
Database Security: Secure PostgreSQL with strong passwords
Backup Encryption: Encrypt sensitive backup data
Access Control: Implement proper user access controls
​
Getting Started
Ready to deploy Chatwoot? Choose your preferred deployment method:
Quick Start with Docker
Get up and running quickly with Docker containers
Linux VM Installation
Traditional server deployment with our automated script
Kubernetes Deployment
Enterprise-scale deployment on Kubernetes
Cloud Providers
One-click deployments on major cloud platforms

Chatwoot Production Deployment Guide
Understanding Chatwoot’s production architecture and deployment requirements

This guide will help you to deploy Chatwoot to production!
​
Architecture
Running Chatwoot in production requires the following set of services.
Chatwoot web servers
Chatwoot workers
PostgreSQL Database
Redis Database
Email service (SMTP servers / SendGrid / Mailgun etc)
Object Storage (S3, Azure Storage, GCS, etc)
architecture
​
Updating your Chatwoot installation
A new version of Chatwoot is released around the first Monday of every month. We also release minor versions when there is a need for hotfixes or security updates.
You can stay tuned to our Roadmap and releases on GitHub. We recommend you to stay up to date with our releases to enjoy the latest features and security updates.
The deployment process for a newer version involves updating your app servers and workers with the latest code. Most updates would involve database migrations as well which can be executed through the following Rails command.
bundle exec rails db:migrate
The detailed instructions can be found in respective deployment guides.
​
Available deployment options
If you want to self host Chatwoot, the recommended approach is to use one of the recommended one click installation options from the below list. If you are comfortable with Ruby on Rails applications, you can also make use of the other deployment options mentioned below.
Heroku (recommended)
Docker (recommended)
Linux
Kubernetes
Chatwoot CTL
​
Cloud Providers
AWS
Azure
DigitalOcean
Google Cloud
Heroku
System Requirements
Hardware and software requirements for self-hosting Chatwoot

This page includes useful information on the requirements that are needed to install and run Chatwoot on your servers.
​
Operating Systems
​
Supported Linux distribution
Ubuntu (20.04)
Installation of Chatwoot is possible on most unix environments, but not officially supported.
​
Microsoft Windows
Chatwoot is developed for Linux-based operating systems. Please consider using a virtual machine to run Chatwoot on windows.
​
Software requirements
​
Ruby versions
Ruby 3.2 and later is required.
You must use the standard MRI implementation of Ruby. Chatwoot needs several Gems that have native extensions.
​
Node.js versions
We only support Node.js 10.13.0 or higher.
We recommend Node 20.x, as it’s faster and the latest.
Chatwoot uses webpack to compile frontend assets, which requires a minimum version of Node.js 20.x.0.
You can check which version you’re running with node -v. If you’re running a version older than v10.13.0, you need to update it to a newer version. You can find instructions to install from community maintained packages or compile from source at the Node.js website.
​
Hardware requirements
​
Storage
The necessary hard drive space largely depends on your usage, the size and number of attachments that you receive through your conversations etc.
Consider using a storage option provided by AWS, Azure, Google Cloud etc, if you want to stay flexible and accommodate the growing storage requirements. Chatwoot also supports other S3 API compatible services viz Minio, DigitalOcean Spaces, Linode Objects etc.
​
CPU
CPU requirements are dependent on the usage and expected workload. Your workload is influenced by factors such as - but not limited to - how active your users are, how many conversations do you receive and the conversation channels which you are using.
The following is the recommended minimum CPU hardware guidance for a handful of example Chatwoot conversation base sizes.
4 cores is the recommended minimum number of cores and supports up to 10,000 conversations a day.
8 cores supports up to 20,000 conversations a day.
More conversations? Consider scaling horizontally by adding more application servers.
​
Memory
Memory requirements are dependent on the usage and expected workload. Your workload is influenced by factors such as - but not limited to - How active your users are, how many conversations do you receive and the conversation channels which you are using.
The following is the recommended minimum Memory hardware guidance for a handful of example Chatwoot conversation base sizes.
4GB RAM is the required minimum memory size and supports up to 10,000 conversations a day.
we are always working to reduce the memory requirement.
8GB RAM supports up to 20,000 conversations a day.
More conversations? Consider scaling horizontally by adding more application servers.
Add at least 1GB of swap memory to the machine to ensure that the machine doesn’t run out of resources during an upgrade.
​
Database
PostgreSQL is the only supported database. We don’t have plans to support any other alternatives as of now.
​
PostgreSQL Requirements
The server running PostgreSQL should have at least 5-10 GB of storage available, though the exact requirements depends on the usage on your Chatwoot Instance.
We highly recommend using the latest stable PostgreSQL versions as these were used for development and testing.
​
Redis
Redis stores the background task queue and various chatwoot configurations cached. The storage requirements for Redis are minimal, You can start with 100MB and scale up as required.
Redis version 7.0 or higher is recommended
​
Sidekiq
Sidekiq processes the background jobs with a multi-threaded process. This process starts with the entire Rails stack but it can grow over time due to memory leaks. On a very active server the Sidekiq process can use 1GB+ of memory.
You can opt to have both the sidekiq workers and rails servers to run on the same machine. But we recommend keeping the worker process and rails server on separate webservers for better scalability.
​
Supported web browsers
Chatwoot supports the following web browsers:
Mozilla Firefox
Google Chrome
Chromium
Apple Safari
Microsoft Edge
Production deployment guide for Linux VM
Deploy Chatwoot on Ubuntu 24.04 LTS using the automated installation script

​
Deploying to Linux VM
This guide will help you install Chatwoot on Ubuntu 24.04 LTS. We have prepared a deployment script for you to run. Refer to the script and feel free to make changes accordingly to the operating system if you are on a non-Ubuntu system.

​
Steps to install
If you plan to use a domain with chatwoot, please add an A record before proceeding. Refer to the Configuring the installation domain section below.
​
1. Create an install.sh file
wget https://get.chatwoot.app/linux/install.sh
chmod +x install.sh
​
2. Execute the script
The script will take care of the initial Chatwoot setup.
./install.sh --install
​
3. Access your installation
Chatwoot Installation will now be accessible at http://{your_ip_address}:3000 or if you opted for domain setup, it will be at https://chatwoot.mydomain.com.
This will also install the Chatwoot CLI(cwctl) starting with Chatwoot v2.7.0. Use cwctl --help to learn more.
​
Configuring The installation Domain
Create an A record for chatwoot.mydomain.com on your domain management system and point it towards the installation IP address.
Continue with the installation script by entering yes when prompted about domain setup.
Enter your domain. The script will take care of configuring Nginx and SSL via LetsEncrypt.
Your Chatwoot installation should be accessible from https://chatwoot.mydomain.com now.
​
Configure the required environment variables
For your Chatwoot installation to properly function, you would need to configure the essential environment variables like FRONTEND_URL, Mailer, and a cloud storage config. Refer Environment variables for the full list.
​
1. Login as chatwoot user and edit the .env file
# Login as chatwoot user
sudo -i -u chatwoot
cd chatwoot
nano .env
​
2. Update environment variables
Refer Environment variables and update the required variables. Save the .env file.
​
3. Restart the Chatwoot server
If you have Chatwoot CLI(cwctl) installed, use cwctl -r.
sudo systemctl restart chatwoot.target
​
Upgrading to a newer version of Chatwoot
Whenever a new version of Chatwoot is released, use the following steps to upgrade your instance.
If you have Chatwoot CLI(cwctl) installed, use cwctl --upgrade to upgrade your Chatwoot installation.
To install cwctl, refer this section below.
If you are on an older version of Chatwoot(< 2.7), follow the manual upgrade steps below if you face errors with cwctl.
Run the following steps on your VM. Make changes based on your OS if you are on a non-Ubuntu system.
# Login as Chatwoot user
sudo -i -u chatwoot

# Navigate to the Chatwoot directory
cd chatwoot

# Pull the latest version of the master branch
git checkout master && git pull

# Ensure the ruby version is upto date
rvm install "ruby-3.3.3"
rvm use 3.3.3 --default

# Update dependencies
bundle
pnpm i

# Recompile the assets
rake assets:precompile RAILS_ENV=production

# Migrate the database schema
RAILS_ENV=production bundle exec rake db:migrate

# Switch back to root user
exit

# Copy the updated targets
cp /home/chatwoot/chatwoot/deployment/chatwoot-web.1.service /etc/systemd/system/chatwoot-web.1.service
cp /home/chatwoot/chatwoot/deployment/chatwoot-worker.1.service /etc/systemd/system/chatwoot-worker.1.service
cp /home/chatwoot/chatwoot/deployment/chatwoot.target /etc/systemd/system/chatwoot.target

# Reload systemd files
systemctl daemon-reload

# Restart the chatwoot server
systemctl restart chatwoot.target
​
Running Rails Console
If you have Chatwoot CLI(cwctl) installed, use cwctl -c.
# Login as Chatwoot user
sudo -i -u chatwoot

# Navigate to the Chatwoot directory
cd chatwoot

# start rails console
RAILS_ENV=production bundle exec rails c
​
Viewing Logs
If you have Chatwoot CLI(cwctl) installed, use cwctl -l web or cwctl -l worker.
Run the following commands in your ubuntu shell
# logs from the rails server
journalctl -u chatwoot-web.1.service -f

# logs from sidekiq
journalctl -u chatwoot-worker.1.service -f
​
Install or Upgrade Chatwoot CLI
If you used an older version of install script(< 2.0), you will not have cwctl in your PATH. To install/upgrade Chatwoot CLI,
wget https://get.chatwoot.app/linux/install.sh -O /usr/local/bin/cwctl && chmod +x /usr/local/bin/cwctl
cwctl --help
The above command requires root access to install cwctl to /usr/local/bin.
​
Troubleshooting
​
If precompile fails
If the asset precompilation step fails with ActionView::Template::Error (Webpacker can't find application.css in /home/chatwoot/chatwoot/public/packs/manifest.json) or if you face issues while restarting the server, try the following command and restart the server.
RAILS_ENV=production rake assets:clean assets:clobber assets:precompile
This command would clear the existing compiled assets and would recompile all the assets. Read more about it here

Docker Chatwoot Production deployment guide
Deploy Chatwoot using Docker containers for production environments

​
Pre-requisites
Before proceeding, make sure you have the latest version of docker and docker-compose installed.
As of now [at the time of writing this doc], we recommend a version equal to or higher than the following.
$ docker --version
Docker version 20.10.10, build b485636
$ docker compose version
Docker Compose version v2.14.1
Container name uses dashes instead of underscores by default with new docker/compose versions. If you are using an older version of docker/compose, replace - with _. Also, use docker-compose instead of docker compose.
​
Steps to deploy Chatwoot using docker-compose
​
1. Install Docker on your VM
# example in ubuntu
apt-get update
apt-get upgrade
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
apt install docker-compose-plugin
​
2. Download the required files
# Download the env file template
wget -O .env https://raw.githubusercontent.com/chatwoot/chatwoot/develop/.env.example
# Download the Docker compose template
wget -O docker-compose.yaml https://raw.githubusercontent.com/chatwoot/chatwoot/develop/docker-compose.production.yaml
​
3. Configure environment variables
Tweak the .env and docker-compose.yaml according to your preferences. Refer to the available environment variables. You could also remove the dependant services like Postgres, Redis etc., in favor of managed services configured via environment variables.
# update redis and postgres passwords
nano .env
# update docker-compose.yaml same postgres pass
nano docker-compose.yaml
​
4. Prepare the database
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
​
5. Start the services
docker compose up -d
​
6. Access your installation
Your Chatwoot installation is complete. Please note that the containers are not exposed to the internet and they only bind to the localhost. Setup something like Nginx or any other proxy server to proxy the requests to the container.
If you want to verify whether the installation is working, try curl -I localhost:3000/api to see if it returns 200. Also, you could temporarily drop the 127.0.0.1:3000:3000 for rails to 3000:3000 in the compose file to access your instance at http://<your-external-ip>:3000. It’s recommended to revert this change back and use Nginx or some proxy server in the front.
​
Additional Steps
Have an Nginx web server acting as a reverse proxy for Chatwoot installation. So that you can access Chatwoot from https://chat.yourdomain.com
Run docker compose run --rm rails bundle exec rails db:chatwoot_prepare whenever you decide to update the Chatwoot images to handle the migrations.
​
Configure Nginx and Let’s Encrypt
​
1. Configure Nginx to serve as a frontend proxy
sudo apt-get install nginx
cd /etc/nginx/sites-enabled
nano yourdomain.com.conf
​
2. Use the following Nginx config
Use the following Nginx config after replacing the yourdomain.com in server_name.
server {
  server_name <yourdomain.com>;

  # Point upstream to Chatwoot App Server
  set $upstream 127.0.0.1:3000;

  # Nginx strips out underscore in headers by default
  # Chatwoot relies on underscore in headers for API
  # Make sure that the config is set to on.
  underscores_in_headers on;
  location /.well-known {
    alias /var/www/ssl-proof/chatwoot/.well-known;
  }

  location / {
    proxy_pass_header Authorization;
    proxy_pass http://$upstream;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Ssl on; # Optional

    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_http_version 1.1;
    proxy_buffering off;

    client_max_body_size 0;
    proxy_read_timeout 36000s;
    proxy_redirect off;
  }
  listen 80;
}
​
3. Verify and reload Nginx config
nginx -t
systemctl reload nginx
​
4. Run Let’s Encrypt to configure SSL certificate
apt install certbot
apt-get install python3-certbot-nginx
mkdir -p /var/www/ssl-proof/chatwoot/.well-known
certbot --webroot -w /var/www/ssl-proof/chatwoot/ -d yourdomain.com -i nginx
​
5. Access your installation
Your Chatwoot installation should be accessible from the https://yourdomain.com now.
​
Steps to build images yourself
We publish our base images to the Docker hub. You should be able to build your Chatwoot web/worker images from these base images.
​
Web
FROM chatwoot/chatwoot:latest
RUN chmod +x docker/entrypoints/rails.sh
ENTRYPOINT ["docker/entrypoints/rails.sh"]
CMD bundle exec bundle exec rails s -b 0.0.0.0 -p 3000
​
Worker
FROM chatwoot/chatwoot:latest
RUN chmod +x docker/entrypoints/rails.sh
ENTRYPOINT ["docker/entrypoints/rails.sh"]
CMD bundle exec sidekiq -C config/sidekiq.yml
The app servers will run available on port 3000. Ensure the images connect to the same database and Redis servers. Provide the configuration for these services via environment variables.
​
Initial database setup
To set up the database for the first time, you must run rails db:chatwoot_prepare. You may get errors if you try to run rails db:migrate at this point.
​
Upgrading
If you’re not using the latest or latest-ce tag, you first need to change the desired tag in your docker-compose file.
After that you can pull the new image and start using them:
docker compose pull
docker compose up -d
Finally you may need to update the database:
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
​
Running Rails Console
docker exec -it $(basename $(pwd))-rails-1 sh -c 'RAILS_ENV=production bundle exec rails c'
​
Chatwoot CE edition docker images
If you want to run Chatwoot CE edition, replace the docker image tag with equivalent foss version tag. Docker tag for current master would be latest-ce. Version specific tags would follow the pattern v*-ce. For example the docker ce edition tag for Chatwoot v2.3.2 would be v2.3.2-ce.

Deploy Chatwoot on Kubernetes using Helm Charts
Deploy Chatwoot on Kubernetes using our official Helm charts

This guide will help you to deploy a production ready Chatwoot instance with Helm Charts.
To quickly try out the charts, follow the two steps below. For a production deployment, please make sure to pass in the required arguments to helm using your custom values.yaml file.
helm repo add chatwoot https://chatwoot.github.io/charts
helm install chatwoot chatwoot/chatwoot

​
Prerequisites
Kubernetes 1.16+
Helm 3.1.0+
PV provisioner support in the underlying infrastructure
The helm installation will create 3 “Persistent Volume Claims” for redis, rails and postgres. Setup up a default “Storage Class” (for automatic PV) or create 3 “Persistent Volumes” with the size of 8GB, before installing chatwoot. If the “Persistent Volume Claims” do not claim the “Persistent Volumes”, leave storageClassName blank (inside the PV .yaml files).
​
Installing the chart
To install the chart with the release name chatwoot, use the following. To deploy it in chatwoot namespace, pass -n chatwoot to the command.
helm install chatwoot chatwoot/chatwoot -f <your-custom-values.yaml> #-n chatwoot
The command deploys Chatwoot on the Kubernetes cluster in the default configuration. The parameters section lists the parameters that can be configured during installation.
List all releases using helm list
​
Uninstalling the chart
To uninstall/delete the chatwoot deployment:
helm delete chatwoot
The command removes all the Kubernetes components associated with the chart and deletes the release.
Persistent volumes are not deleted automatically. They need to be removed manually.
​
Parameters
​
Chatwoot Image parameters
Name	Description	Value
image.repository	Chatwoot image repository	chatwoot/chatwoot
image.tag	Chatwoot image tag (immutable tags are recommended)	v2.16.0
image.pullPolicy	Chatwoot image pull policy	IfNotPresent
​
Chatwoot Environment Variables
Name	Type	Default Value
env.ACTIVE_STORAGE_SERVICE	Storage service. local for disk. amazon for s3.	"local"
env.ASSET_CDN_HOST	Set if CDN is used for asset delivery.	""
env.INSTALLATION_ENV	Sets chatwoot installation method.	"helm"
env.ENABLE_ACCOUNT_SIGNUP	true : allows sign ups, false : (default option) disables all the end points related to sign ups, api_only: disables the UI for signup but you can create sign ups via the account apis.	"false"
env.FORCE_SSL	Force all access to the app over SSL, default is set to false.	"false"
env.FRONTEND_URL	Replace with the URL you are planning to use for your app.	"http://0.0.0.0:3000/"
env.IOS_APP_ID	Change this variable only if you are using a custom build for mobile app.	"6C953F3RX2.com.chatwoot.app"
env.ANDROID_BUNDLE_ID	Change this variable only if you are using a custom build for mobile app.	"com.chatwoot.app"
env.ANDROID_SHA256_CERT_FINGERPRINT	Change this variable only if you are using a custom build for mobile app.	"AC:73:8E:DE:EB:5............"
env.MAILER_SENDER_EMAIL	The email from which all outgoing emails are sent.	""
env.RAILS_ENV	Sets rails environment.	"production"
env.RAILS_MAX_THREADS	Number of threads each worker will use.	"5"
env.SECRET_KEY_BASE	Used to verify the integrity of signed cookies. Ensure a secure value is set.	replace_with_your_super_duper_secret_key_base
env.SENTRY_DSN	Sentry data source name.	""
env.SMTP_ADDRESS	Set your smtp address.	""
env.SMTP_AUTHENTICATION	Allowed values: plain,login,cram_md5	"plain"
env.SMTP_ENABLE_STARTTLS_AUTO	Defaults to true.	"true"
env.SMTP_OPENSSL_VERIFY_MODE	Can be: none, peer, client_once, fail_if_no_peer_cert	"none"
env.SMTP_PASSWORD	SMTP password	""
env.SMTP_PORT	SMTP port	"587"
env.SMTP_USERNAME	SMTP username	""
env.USE_INBOX_AVATAR_FOR_BOT	Bot customizations	"true"
​
Email setup for conversation continuity (Incoming emails)
Name	Type	Default Value
env.MAILER_INBOUND_EMAIL_DOMAIN	This is the domain set for the reply emails when conversation continuity is enabled.	""
env.RAILS_INBOUND_EMAIL_SERVICE	Set this to appropriate ingress channel with regards to incoming emails. Possible values are relay, mailgun, mandrill, postmark and sendgrid.	""
env.RAILS_INBOUND_EMAIL_PASSWORD	Password for the email service.	""
env.MAILGUN_INGRESS_SIGNING_KEY	Set if using mailgun for incoming conversations.	""
env.MANDRILL_INGRESS_API_KEY	Set if using mandrill for incoming conversations.	""
​
Postgres variables
Name	Type	Default Value
postgresql.enabled	Set to false if using external postgres and modify the below variables.	true
postgresql.auth.database	Chatwoot database name	chatwoot_production
postgresql.postgresqlHost	Postgres host. Edit if using external postgres.	""
postgresql.auth.postgresPassword	Postgres password. Edit if using external postgres.	postgres
postgresql.postgresqlPort	Postgres port	5432
postgresql.auth.username	Postgres username.	postgres
​
Redis variables
Name	Type	Default Value
redis.auth.password	Password used for internal redis cluster	redis
redis.enabled	Set to false if using external redis and modify the below variables.	true
redis.host	Redis host name	""
redis.port	Redis port	""
redis.password	Redis password	""
env.REDIS_TLS	Set to true if TLS(rediss://) is required	false
env.REDIS_SENTINELS	Redis Sentinel can be used by passing list of sentinel host and ports.	""
env.REDIS_SENTINEL_MASTER_NAME	Redis sentinel master name is required when using sentinel.	""
​
Logging variables
Name	Type	Default Value
env.RAILS_LOG_TO_STDOUT	string	"true"
env.LOG_LEVEL	string	"info"
env.LOG_SIZE	string	"500"
​
Third party credentials
Name	Type	Default Value
env.S3_BUCKET_NAME	S3 bucket name	""
env.AWS_ACCESS_KEY_ID	Amazon access key ID	""
env.AWS_REGION	Amazon region	""
env.AWS_SECRET_ACCESS_KEY	Amazon secret key ID	""
env.FB_APP_ID	For facebook channel https://one-link.kz/docs/facebook-setup	""
env.FB_APP_SECRET	For facebook channel	""
env.FB_VERIFY_TOKEN	For facebook channel	""
env.SLACK_CLIENT_ID	For slack integration	""
env.SLACK_CLIENT_SECRET	For slack integration	""
env.TWITTER_APP_ID	For twitter channel	""
env.TWITTER_CONSUMER_KEY	For twitter channel	""
env.TWITTER_CONSUMER_SECRET	For twitter channel	""
env.TWITTER_ENVIRONMENT	For twitter channel	""
​
Autoscaling
Name	Type	Default Value
web.hpa.enabled	Horizontal Pod Autoscaling for Chatwoot web	false
web.hpa.cputhreshold	CPU threshold for Chatwoot web	80
web.hpa.minpods	Minimum number of pods for Chatwoot web	1
web.hpa.maxpods	Maximum number of pods for Chatwoot web	10
web.replicaCount	No of web pods if hpa is not enabled	1
worker.hpa.enabled	Horizontal Pod Autoscaling for Chatwoot worker	false
worker.hpa.cputhreshold	CPU threshold for Chatwoot worker	80
worker.hpa.minpods	Minimum number of pods for Chatwoot worker	2
worker.hpa.maxpods	Maximum number of pods for Chatwoot worker	10
worker.replicaCount	No of worker pods if hpa is not enabled	1
​
Install with custom parameters
Specify each parameter using the --set key=value[,key=value] argument to helm install. For example,
helm install my-release \
  --set env.FRONTEND_URL="chat.yourdomain.com"\
    chatwoot/chatwoot
The above command sets the Chatwoot server frontend URL to chat.yourdoamain.com.
Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,
helm install my-release -f values.yaml chatwoot/chatwoot
You can use the default values.yaml file.
​
Postgres
PostgreSQL is installed along with the chart if you choose the default setup. To use an external Postgres DB, please set postgresql.enabled to false and set the variables under the Postgres section above.
​
Redis
Redis is installed along with the chart if you choose the default setup. To use an external Redis DB, please set redis.enabled to false and set the variables under the Redis section above.
​
Autoscaling
To enable horizontal pod autoscaling, set web.hpa.enabled and worker.hpa.enabled to true. Also make sure to uncomment the values under, resources.limits and resources.requests. This assumes your k8s cluster is already having a metrics-server. If not, deploy metrics-server with the following command.
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
​
Upgrading
Do helm repo update and check the version of charts that is going to be installed. Helm charts follows semantic versioning and so if the MAJOR version is different from your installed version, there might be breaking changes. Please refer to the changelog before upgrading.
# update helm repositories
helm repo update
# list your current installed version
helm list
# show the latest version of charts that is going to be installed
helm search repo chatwoot
#if it is major version update, refer to the changelog before proceeding
helm upgrade chatwoot chatwoot/chatwoot -f <your-custom-values>.yaml
​
Troubleshooting
​
pod has unbound immediate PersistentVolumeClaims
Make sure the “Persistent Volume Claims” can be satisfied. Refer to prerequisites.
​
ActionController::InvalidAuthenticityToken HTTP Origin header
ActionController::InvalidAuthenticityToken HTTP Origin header (https://mydomain.com) didn't match request.base_url (http://mydomain.com)
If you are recieving the above error when trying to access the superadmin panel, configure your ingress controller to forward the protocol of the origin request. For nginx ingress, you can do this by setting the proxy_set_header X-Forwarded-Proto https; config. Refer this issue to learn more.

Chatwoot CTL
CLI tool to install and manage a self hosted Chatwoot Linux installation

​
Introduction
Chatwoot CTL(cwctl) is CLI tool to install and manage a self hosted Chatwoot Linux installation.
cwctl aims to abstract away the common bash interactions with a Chatwoot installation and provide an easy to use syntax. This is not intended to be a full replacement.
If you are running a Chatwoot v2.7.0 instance or later, cwctl would have been already installed for you as part of installation.
Check if cwctl is already installed by
cwctl --version
If cwctl is not present, follow the steps below to install Chatwoot CTL.
​
Install or Upgrade Chatwoot CTL
If you used an older version of install script(< 2.0), you will not have cwctl in your PATH. To install/upgrade Chatwoot CTL,
wget https://get.chatwoot.app/linux/install.sh -O /usr/local/bin/cwctl && chmod +x /usr/local/bin/cwctl
cwctl --help
The above command requires root access to install cwctl to /usr/local/bin.
​
Help
To learn more about the options supported by cwctl,
sudo cwctl --help
​
Upgrading to a newer version of Chatwoot
Whenever a new version of Chatwoot is released, use the following steps to upgrade your instance.
sudo cwctl --upgrade
This will upgrade your Chatwoot instance to the latest stable release. If you are running a custom branch in production do not use this to upgrade.
​
Setup Nginx with SSL after installation
To set up Nginx with SSL after initial setup(if you answered no to webserver/SSL setup during the first install)
Please add an A record pointing to your Chatwoot instance IP before proceeding.
sudo cwctl --webserver
​
Restart Chatwoot
sudo cwctl --restart
​
Running Rails Console
sudo cwctl --console
​
Viewing Logs
For Chatwoot web(rails) server logs use,
sudo cwctl --logs web
For Chatwoot worker(sidekiq) server logs use,
sudo cwctl --logs worker
​
Version
To check the version of Chatwoot CTL,
sudo cwctl --version
Environment Variables
Complete reference for Chatwoot environment variables and configuration options

​
The .env File
We use the dotenv-rails gem to manage the environment variables. There is a file called env.example in the root directory of this project with all the environment variables set to empty values. You can set the correct values as per the following options. Once you set the values, you should rename the file to .env before you start the server.
​
Configure frontend URL (domain)
Provide your chatwoot domain as frontend URL.
FRONTEND_URL='https://your-chatwoot-domain.tld'
​
Rails production variables
For production deployment, you have to set the following variables
RAILS_ENV=production
SECRET_KEY_BASE=replace_with_your_own_secret_string
You can generate SECRET_KEY_BASE using rake secret command from the project root folder. If you dont have rails installed, use head /dev/urandom | tr -dc A-Za-z0-9 | head -c 63 ; echo ''.
SECRET_KEY_BASE should be alphanumeric. Avoid special characters or symbols.
​
Database configuration
Postgres can be configured in two ways: via DATABASE_URL or setting up independent Postgres variables.
​
Configure Postgres
Set the DATABASE_URL variable with value as Postgres connection URI to connect to the database.
The URI is of the format
postgresql://[user[:password]@][netloc][:port][,...][/dbname][?param1=value1&...]
Or you can set the following environment variables to configure Postgres. Replace the values here with yours. Skip this if you have configured DATABASE_URL.
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot_production
POSTGRES_USERNAME=admin
POSTGRES_PASSWORD=password
​
Configure Redis
For development, you can use the following URL to connect to Redis. For production, configure your Redis URL.
REDIS_URL='redis://127.0.0.1:6379'
To authenticate Redis connections made by the app server and sidekick, if it’s protected by a password, use the following environment variable to set the password.
REDIS_PASSWORD=
​
Configure emails
For development, you don’t need an email provider. Chatwoot uses the letter-opener gem to test emails locally
For production use, please configure the following variables.
# could user either `email@yourdomain.com` or `BrandName <email@yourdomain.com>`
MAILER_SENDER_EMAIL=
and based on your SMTP server the following variables
SMTP_ADDRESS=
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_TLS=
SMTP_SSL=
​
Postfix
Follow these steps if you want to use a selfhosted mail server with Chatwoot. This is the default behavior starting from v2.12.0 and relies on SMTP_ADDRESS environment variable not being set.
sudo apt install -y postfix
Choose internet-site when prompted and enter the domain name you used with Chatwoot setup for System mail name.
By default, all major cloud provider have blocked port 25 used for sending emails as part of their spam combat effects. Please raise a support ticket with your cloud provider to enable outbound access on port 25 for this to work. Refer AWS, GCP, Azure and DigitalOcean for more details.
Also please add MX and PTR records for your domain. If your emails are being flagged by Gmail and Outlook, setup SPF and DKIM records for your domain as well. This should improve your email reputation.
​
Amazon SES
SMTP_ADDRESS=email-smtp.<region>.amazonaws.com
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_USERNAME=<Your SMTP username>
SMTP_PASSWORD=<Your SMTP password>
​
SendGrid
For clarification, the SMTP_USERNAME should be set to the literal text apikey—this is not the actual API key. SendGrid uses ‘apikey’ as the standard username for its services.
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_AUTHENTICATION=plain
SMTP_DOMAIN=<your verified domain>
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=<your Sendgrid API key>
​
MailGun
SMTP_ADDRESS=smtp.mailgun.org
SMTP_AUTHENTICATION=plain
SMTP_DOMAIN=<Your domain, this has to be verified in Mailgun>
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_PORT=587
SMTP_USERNAME=<Your SMTP username, view under Domains tab>
SMTP_PASSWORD=<Your SMTP password, view under Domains tab>
​
Mandrill
If you would like to use Mailchimp to send your emails, use the following environment variables:
Mandrill is the transactional email service for Mailchimp. You need to enable transactional email and login to mandrillapp.com.
SMTP_ADDRESS=smtp.mandrillapp.com
SMTP_AUTHENTICATION=plain
SMTP_DOMAIN=<Your verified domain in Mailchimp>
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_PORT=587
SMTP_USERNAME=<Your SMTP username displayed under Settings -> SMTP & API info>
SMTP_PASSWORD=<Any valid API key, create an API key under Settings -> SMTP & API Info>
​
Configure default language
DEFAULT_LOCALE='en'
​
Configure storage
Chatwoot uses active storage for storing attachments. The default storage option is the local storage on your server.
But you can change it to use any of the cloud providers like amazon s3, microsoft azure, google gcs etc. Refer configuring cloud storage for additional environment variables required.
ACTIVE_STORAGE_SERVICE=local
When local storage is used the files are stored under /storage directory in the chatwoot root folder.
It is recommended to use a cloud provider for your chatwoot storage to ensure proper backup of the stored attachments and prevent data loss.
​
Rails Logging Variables
By default, Chatwoot will capture info level logs in production. Ref rails docs for the additional log-level options. We will also retain 1 GB of your recent logs and your last shifted log file. You can fine-tune these settings using the following environment variables
# possible values: 'debug', 'info', 'warn', 'error', 'fatal' and 'unknown'
LOG_LEVEL=
# value in megabytes
LOG_SIZE= 1024
​
Configure FB Channel
To use FB Channel, you have to create a Facebook app in the developer portal. You can find more details about creating FB channels here
FB_VERIFY_TOKEN=
FB_APP_SECRET=
FB_APP_ID=
​
Using CDN for asset delivery
With the release v1.8.0, we are enabling CDN support for Chatwoot. If you have a high traffic website, we recommend to setup a CDN for your asset delivery. Read setting up CloudFront as your CDN guide.
​
Enable new account signup
By default, Chatwoot will not allow users to create an account[multi-tenancy] from the login page. However, if you are setting up a public server, you can enable signup using:
ENABLE_ACCOUNT_SIGNUP=true
​
Enable direct upload to storage cloud
By default, Chatwoot will upload the files to the application server and then it will push them to the cloud storage. We have introduced the direct upload functionality so that we can upload the file directly to the cloud storage. This has been built according to rails new direct upload functionality documented here. Set below environment variable to true to use the direct upload feature.
Make sure to follow this guide and set the appropriate CORS configuration on your cloud storage after setting DIRECT_UPLOADS_ENABLED to true.
DIRECT_UPLOADS_ENABLED=true
​
Google OAuth
To enable Google OAuth in Chatwoot, you need to provide the client ID, client secret, and callback URL. You can find the instructions to generate the details here.
Set the GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET environment variables in your Chatwoot installation using the values you copied from the Google API Console. Set the GOOGLE_OAUTH_CALLBACK_URL environment variable to the callback URL you used in the Google API Console. Here’s an example of the same
GOOGLE_OAUTH_CLIENT_ID=369777777777-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=ABCDEF-GHijklmnoPqrstuvwX-yz1234567
GOOGLE_OAUTH_CALLBACK_URL=https://<your-server-domain>/omniauth/google_oauth2/callback
The callback URL should comply with the format in the example above. This endpoint cannot be changed at the moment.
After setting these environment variables, restart your Chatwoot server to apply the changes. Now, users will be able to sign in using their Google accounts.
​
LogRocket
To enable LogRocket in Chatwoot, you need to provide the project ID from LogRocket. Here are the steps to follow:
Open the LogRocket website and create an account or sign in to your existing account.
After signing in, create a new project in LogRocket by clicking on “Create new project”.
Enter a name for your project, and save the project ID.
Set the LOG_ROCKET_PROJECT_ID environment variable in your .env file with the project ID you copied from LogRocket.
LOG_ROCKET_PROJECT_ID=abcd12/pineapple-on-pizza
After setting this environment variable, restart your Chatwoot server to apply the changes. Now, LogRocket will start capturing user sessions on your Chatwoot installation.
MFA Setup Guide
​
Overview
Multi-Factor Authentication (MFA) adds an extra layer of security to your Chatwoot installation by requiring users to provide a time-based one-time password (TOTP) in addition to their regular password. This guide will help you enable MFA for your self-hosted Chatwoot instance.
​
Prerequisites
Chatwoot version 4.6 or higher
Access to your server’s environment variables
Ability to restart your Chatwoot application
​
Configuration Steps
​
Step 1: Generate Encryption Keys
MFA requires Active Record Encryption keys to securely store user secrets. Use Rails’ built-in encryption initialization command:
# SSH into your Chatwoot server
cd /path/to/chatwoot

# Generate all required encryption keys at once
rails db:encryption:init
This command will output all three required keys:
# Example output:
active_record_encryption:
  primary_key: EGY8WhulUOXixybod7ZWwMIL68R9o5kC
  deterministic_key: aPA5XyALhf75NNnMzaspW7akTfZp0lPY
  key_derivation_salt: xEY0dt6TZcAMg52K7O84wYzkjvbA62Hz
Important:
Store these keys securely. You’ll need them for the next step and for any future server migrations
Use different keys for each environment (development, staging, production)
Never share or commit these keys to version control
​
Step 2: Configure Environment Variables
Add the following variables to your .env file using the keys generated in Step 1:
# Active Record Encryption keys (required for MFA/2FA functionality)
# Replace with the actual keys from rails db:encryption:init output
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=EGY8WhulUOXixybod7ZWwMIL68R9o5kC
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=aPA5XyALhf75NNnMzaspW7akTfZp0lPY
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=xEY0dt6TZcAMg52K7O84wYzkjvbA62Hz
​
User Setup Guide
Once MFA is configured on your server, users can enable it for their accounts:
​
For Users: Enabling MFA
Log in to your Chatwoot account
Navigate to Profile Settings → Security
Click Enable Two-Factor Authentication
Scan the QR code with an authenticator app:
Google Authenticator
Microsoft Authenticator
Authy
1Password
Or any TOTP-compatible app
Enter the 6-digit code from your authenticator app
Save your backup codes in a secure location (10 alphanumeric 8-character codes)
Click Verify and Enable
​
For Users: Logging in with MFA
Enter your email and password as usual
When prompted, enter the 6-digit code from your authenticator app
Alternatively, use a backup code if you don’t have access to your authenticator
​
For Users: Disabling MFA
Go to Profile Settings → Security
Click Disable Two-Factor Authentication
Enter your current 6-digit code and password
Confirm the action
​
Troubleshooting
​
MFA Not Available
If users don’t see MFA options:
Check encryption keys are set:
echo $ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
Should display your key, not blank.
Verify all three keys are configured:
rails runner "
  puts 'Primary Key: ' + (ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'].present? ? '✓' : '✗')
  puts 'Deterministic Key: ' + (ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY'].present? ? '✓' : '✗')
  puts 'Derivation Salt: ' + (ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT'].present? ? '✓' : '✗')
"
Ensure application was restarted after configuration
​
Lost Authenticator Access
If a user loses access to their authenticator:
Using backup codes:
Users can log in with one of their saved backup codes (8-character alphanumeric)
Each code can only be used once
Example format: A1B2C3D4
Admin intervention (if backup codes are also lost):
# Reset MFA for a specific user
rake mfa:reset[user@example.com]

# Generate new backup codes for a user
rake mfa:generate_backup_codes[user@example.com]

# Reset MFA for all users
rake mfa:reset_all
​
Security Best Practices
​
Key Management
Never commit encryption keys to version control
Generate separate keys for each environment using rails db:encryption:init
Use different keys for development, staging, and production environments
Rotate keys periodically (requires re-enrollment of all users)
Backup keys securely - losing them means users can’t authenticate
​
Server Security
Use HTTPS only - MFA codes can be intercepted over HTTP
Enable rate limiting - Chatwoot includes built-in rate limiting for login attempts
Regular updates - Keep Chatwoot and dependencies updated
Monitor failed attempts - Review logs for suspicious activity
​
Migration and Disaster Recovery
​
Migrating to a New Server
Export environment variables from old server (including encryption keys)
Backup database with MFA data
Set up new server with the same encryption keys (do NOT generate new ones)
Restore database
Test MFA login with a test account
Note: You must use the exact same encryption keys on the new server. If you generate new keys with rails db:encryption:init, existing MFA secrets will become unreadable.
​
Disaster Recovery
If encryption keys are lost:
All users will need to re-enable MFA
Communicate the issue to users promptly
This guide applies to Chatwoot version 4.6 and above
Optimizing Configurations
Performance optimization guide for Chatwoot self-hosted deployments

This document helps you to fine-tune various configuration values available in Chatwoot to extract the maximum performance out of your Chatwoot Installation.
​
Puma
Chatwoot uses Puma as its Webserver. So let’s start with a brief introduction to Puma workers and threads.
Puma is a popular web server for Ruby on Rails applications, and it uses multiple workers and threads to handle incoming requests. Each Worker runs its own instance of the application, and each thread within a worker can handle a single request at a time.
Now, let’s move on to how you can configure Puma workers and threads using environment variables.
​
Workers
Each Puma worker is a separate process that runs an instance of the Ruby application. Each Worker has its own event loop that can handle incoming requests concurrently using multiple threads.
When the Puma server receives a request, it is assigned to a worker process in a round-robin fashion. Once a worker receives a request, it assigns the request to an available thread within its process. Each thread then handles the request, including any required database queries, calculations, and other processing tasks. Using multiple worker processes allows Puma to handle multiple requests concurrently without blocking other requests or causing a bottleneck.
​
Configuring the number of workers
The WEB_CONCURRENCY environment variable can be used to configure the number of workers in Puma. It’s important to consider the number of available CPU cores and aim for a ratio of workers to cores that allows the server to run at maximum capacity without causing performance issues. It’s recommended to have a number of workers that matches or is slightly less than the number of available CPU cores to avoid competition for CPU time, which can lead to performance issues.
WEB_CONCURRENCY=2
The default configuration in Chatwoot for WEB_CONCURRENCY is 0. I.e. it runs one Worker. This is to ensure the application works on machines with a lower configuration. If you run Chatwoot on machines with higher specs, fine-tune this configuration accordingly.
​
Threads
Each Puma thread is a lightweight execution context that can handle a single request at a time. When a worker process receives a request, it is assigned to an available thread within that process. Each thread then handles the request, including any required database queries, calculations, and other processing tasks.
Using multiple threads can increase concurrency and performance, but balancing the number of threads with the available CPU resources is essential to avoid competition for CPU time. The number of threads can be configured using the following environment variables.
# Only required to configure if absolutely necessary
# Defaults to Max threads value by default
# RAILS_MIN_THREADS=5
RAILS_MAX_THREADS=5
The default configuration in Chatwoot for RAILS_MAX_THREADS values is 5. You can fine-tune it based on your requirements. The value of RAILS_MIN_THREADS defaults to RAILS_MAX_THREADS unless a specific value is provided.
​
Fine-tuning
TLDR: You can configure WEB_CONCURRENCY to the number of CPU cores and then fine-tune the number of RAILS_MAX_THREADS based on the available memory and CPU resources. While running the sidekiq and rails server on a single machine, consider the sidekiq configuration while determining these numbers.
References:
https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server
https://www.speedshop.co/2017/10/12/appserver.html
https://github.com/ankane/the-ultimate-guide-to-ruby-timeouts#puma
​
Sidekiq
Sidekiq is a popular job processing library for Ruby on Rails applications. Chatwoot uses it as a simple and efficient way to execute background jobs asynchronously in the Rails application.
Sidekiq uses Redis to manage a job queue, allowing you to run multiple workers in parallel, each processing jobs from the queue. This makes it easy to distribute workloads and handle large volumes of jobs without bogging down your Rails application’s main thread.
You can configure the number of sidekiq workers using the following environment variables.
# the default value in Chatwoot is 10 
SIDEKIQ_CONCURRENCY=10
If you are running sidekiq on dedicated pods, you can fine-tune the SIDEKIQ_CONCURRENCY number to extract the maximum performance of the available CPU resources.
​
Database Connections
When a Ruby on Rails application is launched, it creates a pool of database connections that are stored in memory. These connections are established with the database server at the beginning of the application and are kept open throughout the life of the application. When a request is made to the application that requires access to the database, the application server will retrieve a connection from the pool and use it to process the request. Once the request is complete, the connection is returned to the pool to be used for future requests.
The size of the database pool in Chatwoot is configured automatically based on the values of RAILS_MAX_THREADS and SIDEKIQ_CONCURRENCY
https://github.com/chatwoot/chatwoot/blob/4d719a8fe33bed72ec57812e174dab1874315340/config/database.yml#L7
Ref:
https://stackoverflow.com/questions/40412611/in-puma-how-do-i-calculate-db-connections
If you have a database server with higher resources available, you can leverage it by bumping up the number of rails and sidekiq pods so that more of the connection limit is being used.
​
FAQ
​
Getting ActiveRecord::ConnectionTimeoutError errors.
There is a potential bug with Chatwoot’s implementation of rack-timeout, in specific installations, which results in connections not being released properly. For the time being, you can set the following environment variable to disable rack-timeout if you are experiencing this.
RACK_TIMEOUT_SERVICE_TIMEOUT=0
Cloudfront CDN
Configure Cloudfront as a CDN for Chatwoot assets

This document helps you to configure Cloudfront as the asset host for Chatwoot. If you have a high traffic website, we would recommend setting up a CDN for Chatwoot.
​
Configure a Cloudfront distribution
Step 1: Create a Cloudfront distribution.
create-distribution
Step 2: Select “Web” as delivery method for your content.
web-delivery-method
Step 3: Configure the Origin Settings as the following.
origin-settings
Provide your Chatwoot Installation URL under Origin Domain Name.
Select “Origin Protocol Policy” as Match Viewer.
Step 4: Configure Cache behaviour.
cache-behaviour
Configure Allowed HTTP methods to use GET, HEAD, OPTIONS.
Configure Cache and origin request settings to use Use legacy cache settings.
Select Whitelist for Cache Based on Selected Request Headers.
Add the following headers to the Whitelist Headers.extra-headers
Access-Control-Request-Headers
Access-Control-Request-Method
Origin
Set the Response headers policy to CORS-With-Preflight
Step 5: Click on Create Distribution. You will be able to see the distribution as shown below. Use the Domain name listed in the details as the ASSET_CDN_HOST in Chatwoot.
cdn-distribution-settings
​
Add ASSET_CDN_HOST in Chatwoot
Your Cloudfront URL will be of the format <distribution>.cloudfront.net.
Set
ASSET_CDN_HOST=<distribution>.cloudfront.net
in the environment variables.
​
Benefits of Using CDN
Using a CDN provides several benefits for your Chatwoot installation:
Faster Asset Loading: Assets are served from edge locations closer to users
Reduced Server Load: Static assets are served from CDN, reducing load on your application server
Better User Experience: Faster page load times improve user experience
Global Availability: Assets are cached globally for users worldwide
Bandwidth Savings: Reduces bandwidth usage on your origin server
​
Troubleshooting
​
CORS Issues
If you encounter CORS issues after setting up CloudFront:
Ensure the CORS headers are properly configured in CloudFront
Verify that your CORS_ORIGINS environment variable includes your CDN domain:
CORS_ORIGINS=https://yourdomain.com,https://d1234567890.cloudfront.net
​
Cache Invalidation
To invalidate CloudFront cache after updating assets:
Go to CloudFront console
Select your distribution
Create an invalidation for /* to clear all cached assets
​
SSL Certificate
For custom domain names with CloudFront:
Request an SSL certificate in AWS Certificate Manager (ACM)
Configure the certificate in your CloudFront distribution
Update your DNS to point to the CloudFront distribution
SSL certificates for CloudFront must be requested in the US East (N. Virginia) region regardless of where your distribution is located.
Super Admin Console
Guide to accessing and using the Super Admin Console and Sidekiq monitoring

You will need a user account with super admin privileges to access the super admin console and Sidekiq console.
The first user created during onboarding is a super admin.
​
Access superadmin console
Access <chatwoot-installation-url>/super_admin.
​
Creating new super admins
Use the super admin console and navigate to the user’s section
Click on the new user button, fill in the details, and select the type to be super admin
​
Access Sidekiq via the super admin console
Access <chatwoot-installation-url>/super_admin.
Authenticate using the admin credentials created during the installation.
You can access the Sidekiq option on the sidebar.
​
Access Rails console
Run the following command in your console from the root folder of your Chatwoot Rails app.
RAILS_ENV=production bundle exec rails c
If you have cwctl, use cwctl --console.
If you running Chatwoot in a Docker container, you would need to access the shell inside your container first.
If you are running Chatwoot on Caprover, use the following command to access the command line.
docker exec -it $(docker ps --filter name=srv-captain--chatwoot-web -q) /bin/sh
APM and Tracing
Configure APM and error monitoring tools for Chatwoot

Chatwoot supports various APM and monitoring tools. You can enable them by configuring the given environment variables.
​
Sentry
Provide your sentry dsn.
SENTRY_DSN=
​
Scout
Provide values for the following environment variables. Refer scout documentation for additional options.
## https://scoutapm.com/docs/ruby/configuration
# SCOUT_KEY=YOURKEY
# SCOUT_NAME=YOURAPPNAME (Production)
# SCOUT_MONITOR=true
​
NewRelic
Enable Newrelic by configuring the license key. Refer newrelic documentation for additional options.
# https://docs.newrelic.com/docs/agents/ruby-agent/configuration/ruby-agent-configuration/
# NEW_RELIC_LICENSE_KEY=
​
DataDog
Datadog requires an agent running on the host machine to which the tracing library can send data. Chatwoot ruby code contains the tracing library, but you need to configure the agent in your host machine/docker environment for the integration to work.
Enable Datadog in chatwoot by configuring the trace agent url.
## https://github.com/DataDog/dd-trace-rb/blob/master/docs/GettingStarted.md#environment-variables
# DD_TRACE_AGENT_URL=http://localhost:8126
​
Running Datadog agent in local via docker
# to run in your local machine binding to port 8126
# replace <dd API key> and dd_site as required

docker run -d --name dd-agent -v /var/run/docker.sock:/var/run/docker.sock:ro -v /proc/:/host/proc/:ro -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro -p 8126:8126  -e DD_API_KEY=<dd api key> -e DD_SITE="datadoghq.com" gcr.io/datadoghq/agent:7
Refer Datadog documentation to install the agent in specific environments like Ubuntu, Docker, kubernetes etc.

Rate Limiting
Configure rate limiting to protect your Chatwoot installation from abuse

To protect the system from abusive requests, Chatwoot makes use of rack_attack gem. You could customize the configuration to suit your needs by updating, config/initializers/rack_attack.rb
​
Default Rate Limits
Chatwoot will throttles requests by IP at 60rpm, Unless the request is from an allowed IP ['127.0.0.1', '::1']
Signup Requests are limited by IP at 5 requests per 5 minutes.
SignIn Requests are limited by IP at 5 requests per 20 seconds.
SignIn Requests are limited by email address at 20 requests per 5 minutes for a specific email.
Reset Password Requests are limited at 5 requests per 1 hour for a specific email.
​
Attachment Restrictions
Contact/Inbox Avatar attachment file types are limited to jpeg, gif and png.
Contact/Inbox Avatar attachment file size is limited to 15MB.
Website Channel message attachments are limited to types [‘image/png’, ‘image/jpeg’, ‘image/gif’, ‘image/bmp’, ‘image/tiff’, ‘application/pdf’, ‘audio/mpeg’, ‘video/mp4’, ‘audio/ogg’, ‘text/csv’]
Website Channel message attachments are limited to 40MB size limit.
​
Disabling Rack attack on your instance
You can control the behaviour of rack attack in your instance via the following environment variables.
## Rack Attack configuration
## To prevent and throttle abusive requests.
# Disable if you are getting too many request errors for custom use cases
# ENABLE_RACK_ATTACK=true
# Control the allowed number of requests
# RACK_ATTACK_LIMIT=300
# Control whether you want to enable rack attack for widget APIs
# ENABLE_RACK_ATTACK_WIDGET_API=true

Supported Providers
Configure cloud storage providers for Chatwoot file storage

​
Configure Cloud Storage
Chatwoot uses Active Storage for storing attachments. The default storage option is local storage on your server, but you can configure cloud providers for better scalability and backup.
It is recommended to use a cloud provider for your Chatwoot storage to ensure proper backup of stored attachments and prevent data loss.
​
Using Amazon S3
You can get started with Creating an S3 bucket and Create an IAM user to configure the following details.
Configure the following env variables.
ACTIVE_STORAGE_SERVICE=amazon
S3_BUCKET_NAME=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
​
Using Google GCS
Starting with version 2.17+, wrap the GCS_CREDENTIALS environment variable in single quotes.
Configure the following env variables.
ACTIVE_STORAGE_SERVICE=google
GCS_PROJECT=
GCS_CREDENTIALS=
GCS_BUCKET=
The value of the GCS_CREDENTIALS should be a json formatted string containing the following keys.
{
  "type": "service_account",
  "project_id" : "",
  "private_key_id" : "",
  "private_key" : "",
  "client_email" : "",
  "client_id" : "",
  "auth_uri" : "",
  "token_uri" : "",
  "auth_provider_x509_cert_url" : "",
  "client_x509_cert_url" : ""
}
When pasting the credentials to the ENV file, make sure to remove the new lines and paste it into a single line.
GCS_CREDENTIALS={"type": "service_account","project_id": "","private_key_id": "","private_key": "","client_email": "","client_id": "","auth_uri": "","token_uri": "","auth_provider_x509_cert_url": "","client_x509_cert_url": ""}
​
Using Microsoft Azure
Configure the following env variables.
ACTIVE_STORAGE_SERVICE=microsoft
AZURE_STORAGE_ACCOUNT_NAME=
AZURE_STORAGE_ACCESS_KEY=
AZURE_STORAGE_CONTAINER=
​
Using Amazon S3 Compatible Service
To use an s3 compatible service such as DigitalOcean Spaces, Minio etc..
Configure the following env variables.
ACTIVE_STORAGE_SERVICE=s3_compatible
STORAGE_BUCKET_NAME=
STORAGE_ACCESS_KEY_ID=
STORAGE_SECRET_ACCESS_KEY=
STORAGE_REGION=nyc3
STORAGE_ENDPOINT=https://nyc3.digitaloceanspaces.com
#set force_path_style to true if using minio
#STORAGE_FORCE_PATH_STYLE=true
S3 Bucket
Configure Amazon S3 bucket as storage in Chatwoot

​
Using Amazon S3
You can get started with Creating an S3 bucket and Create an IAM user to configure the following details.
Configure the following env variables.
ACTIVE_STORAGE_SERVICE='amazon'
S3_BUCKET_NAME=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
​
S3 Bucket policy
Inorder to use S3 bucket in Chatwoot, a policy has to be set with the correct credentials. A sample policy is given below, as the listed actions are required for the storage to work.
{
    "Version": "2012-10-17",
    "Id": "Policyxxx",
    "Statement": [
        {
            "Sid": "Stmtxxx",
            "Effect": "Allow",
            "Principal": {
                "AWS": "your-user-arn"
            },
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        }
    ]
}
Replace your bucket name in the appropriate places.
User ARN can be found using the following steps:
Login to AWS Console. Go to IAM, and click on Users from the left sidebar. You will be to see the list of users as follows.
s3-users-list
Click on the user, you will be to see a screen as shown below. Copy the User ARN and paste it in the above policy.
user-arn
Add CORS Configuration on your S3 buckets
You need to configure CORS settings to the respective storage cloud to support Direct file uploads from the widget and the Chatwoot dashboard.
Refer to this link for more information: https://edgeguides.rubyonrails.org/active_storage_overview.html#cross-origin-resource-sharing-cors-configuration
To make CORS configuration changes on S3:
Go to your S3 bucket
Click on the permissions tab.
Scroll to Cross-origin resource sharing (CORS) and click on Edit and add the respective changes shown below.
aws-cors-setup
Add your Chatwoot URL to the AllowedOrigin as shown below.
[
  {
    "AllowedHeaders": [
      "*"
    ],
    "AllowedMethods": [
      "PUT",
      "POST",
      "DELETE",
      "GET"
    ],
    "AllowedOrigins": [
      "<add-your-domain-here eg: https://one-link.kz>"
    ],
    "ExposeHeaders": [
      "Origin",
      "Content-Type",
      "Content-MD5",
      "Content-Disposition"
    ],
    "MaxAgeSeconds": 3600
  }
]
GCS Bucket
Configure Google Cloud Storage bucket as storage in Chatwoot

Chatwoot supports Google Cloud storage as the storage provider. To enable GCS in Chatwoot, follow the below mentioned steps.
Set google as the active storage service in the environment variables
ACTIVE_STORAGE_SERVICE='google'
​
Get project ID variable
Login to your Google Cloud console. On your home page of your project you will be able to see the project id and project name as follows.
get-your-project-id
GCS_PROJECT=your-project-id
​
Setup GCS Bucket
Go to Storage -> Browser. Click on “Create Bucket”. You will be presented with a screen as shown below. Select the default values and continue.
create-a-bucket
Once this is done you will get the bucket name. Set this as GCS_BUCKET.
GCS_BUCKET=your-bucket-name
​
Setup a service account
Go to Identity & Services -> Identity -> Service Accounts. Click on “Create Service Account”.
Provice a name and an ID for the service account, click on create. You will be asked to “Grant this service account access to the project” Select Cloud Storage -> Storage Admin as shown below.
storage-admin
​
Add service account to the bucket
Go to Storage -> Browser -> Your bucket -> Permissions. Click on add. On “New members” field select the service account you just created.
Select role as Cloud Storage -> Storage Admin and save.
permissions
​
Generate a key for the service account
Go to Identity & Services -> Identity -> Service Accounts -> Your service account. There is a section called Keys. Click on Add Key. You will be presented with an option like the one below. Select JSON from the option.
json
Copy the json file content and set it as GCS_CREDENTIALS
A sample credential file is of the following format.
{
  "type": "service_account",
  "project_id": "",
  "private_key_id": "",
  "private_key": "",
  "client_email": "",
  "client_id": "",
  "auth_uri": "",
  "token_uri": "",
  "auth_provider_x509_cert_url": "",
  "client_x509_cert_url": ""
}
When pasting the credentials to the ENV file, make sure to remove the new lines and paste it into a single line.
GCS_CREDENTIALS={"type": "service_account","project_id": "","private_key_id": "","private_key": "","client_email": "","client_id": "","auth_uri": "","token_uri": "","auth_provider_x509_cert_url": "","client_x509_cert_url": ""}
If you are running Chatwoot v2.17+, make sure to wrap GCS_CREDENTIALS in single quotes.
Introduction to Email Channel Configuration
Overview of email channel configuration for self-hosted Chatwoot

Email is one of the core channels in Chatwoot, and for self-hosted installations the configuration depends entirely on how your mail infrastructure is set up. Different teams use different providers—Google Workspace, Microsoft 365, custom SMTP/IMAP servers, or even forwarding-based workflows. Because of this, Chatwoot provides multiple ways to connect a mailbox, each with slightly different requirements, security properties, and operational trade-offs.
This guide introduces the five supported configurations available in Chatwoot for setting up email channels in a self-hosted environment. All of these methods allow Chatwoot to send and receive email, but the authentication flow, inbound routing, and outbound delivery differ based on your setup.
​
Google (OAuth based)
If you are using Gmail or Google Workspace, you can connect your mailbox using Google OAuth. This provides a secure, standards-based authentication flow without managing app passwords. Chatwoot will use Google’s SMTP and IMAP servers for sending and receiving.
Click here to learn more about Google Workspace Setup.
​
Microsoft (OAuth based)
For organizations using Microsoft 365 or Outlook, you can connect your mailbox using Microsoft OAuth. Chatwoot integrates with Microsoft’s SMTP and IMAP endpoints for full send/receive capability.
Click here to learn more about Microsoft Setup.
​
Standard SMTP + IMAP
This configuration supports any custom mail provider by allowing you to set standard SMTP credentials for outbound mail and IMAP credentials for inbound. This works with on‑prem servers, commercial providers, or any setup that supports username/password authentication.
​
Forwarding Rule (Email → Chatwoot Ingress)
Instead of configuring IMAP, some teams prefer to forward incoming emails directly to Chatwoot. If your mail provider supports forwarding rules, you can send inbound email to Chatwoot’s ingress address, which Chatwoot will process as incoming messages. Outbound email will use your configured SMTP provider.
​
IMAP (Inbound Only) + Chatwoot Mailer (Outbound)
In this mode, Chatwoot pulls inbound email through IMAP but sends outbound messages using Chatwoot’s mailer configuration. This is useful when your mail provider imposes SMTP restrictions or when you want a consistent outbound delivery method across channels.
You just need to configure IMAP settings here.
Google Workspace
Configure an OAuth app for Gmail

At present, Gmail integration operates through less-secure apps. However, as of June 15, 2024, Google Workspace will cease to support these less-secure apps. This will affect the Gmail integration in Chatwoot. To ensure that your Gmail integration continues to work, you will need to set up an OAuth app in Google Workspace.
Existing setups will continue to work until September 30, 2024. However, we recommend setting up an OAuth app as soon as possible to avoid any disruptions.
This guide will walk you through the process of setting up an OAuth app in Google Workspace.
​
Register the app
To enable Google OAuth in Chatwoot, you need to provide the client ID, client secret, and callback URL. You can find the instructions to generate these details here. Once you have followed these steps, you will be able to get a Client ID and Secret.
register-an-app
Use the callback URL https://<your-instance-url>/google/callback when registering the app. This URL is used to redirect the user back to the Chatwoot instance after authentication.
Set the GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET environment variables in your Chatwoot installation using the values you copied from the Google API Console.
GOOGLE_OAUTH_CLIENT_ID=369777777777-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=ABCDEF-GHijklmnoPqrstuvwX-yz1234567
If you have already setup Google OAuth login flow You can use the same app, by simply adding the new callback URL. Do not remove the previous callback URL.
After setting these environment variables, restart your Chatwoot server to apply the changes. Now, users will be able to sign in using their Google accounts.
You will notice that the app you are using is in testing mode; we will cover that later in the guide. For now, you can ignore it.
​
Configure the application
To fetch the emails from the client inbox, you need to configure the correct scopes. The following scopes are required:
https://mail.google.com/: To read, send, delete, and manage your email.
email: To view the user’s email address.
profile: To view the name and picture etc.
You can configure the scopes in the Google API Console by following the steps below:
Go to the Google API Console.
Select the project you created earlier.
Click on the “OAuth consent screen” tab and click on the “Edit App” button.
Add the required scopes in the “Scopes for Google APIs” section.
Click on the “Save” button.
Here’s a demo showing how to add the https://mail.google.com/ scope:
Demo add scope
​
Publishing the app
If you’re using Chatwoot within an organization with fewer than 100 users, you can continue to use the app in testing mode. However, if you’re using Chatwoot in an organization with more than 100 users or using the app to serve multiple clients, you will need to publish the app to make it available to all users.
To publish the app, you need to go through the verification process since we use a restricted scope. You can find the instructions to verify the app here.
It’s important to note that the verification process can take a few days to complete. Once the app is verified, you can publish it and make it available to all users.
Outlook & Microsoft 365 Email
Configure an OAuth app for Outlook & Microsoft 365 emails

Microsoft no longer permits the use of username and password to retrieve emails from Outlook & Microsoft 365 accounts. They have deprecated the basic auth option. To enable the Outlook/Microsoft 365 email channel in your self-hosted instance, you must configure an OAuth app.
This guide helps you set up an Entra ID App (formerly Azure Active Directory) and use the credentials in Chatwoot. By doing so, you can authenticate your Outlook/Microsoft 365 account as an email channel.
​
Register the app
For a more detailed guide on how to set up the Microsoft Identity platform, please refer to the here.
To access the Microsoft Entra Admin Center, go to entra.microsoft.com and log in with your Microsoft account. Once logged in, navigate to the Identity section on the left-hand sidebar. In the Identity section, locate the “Applications” menu and click on “App Registrations” from the submenu. On the “App Registrations” page, click on the “New Registration” option. You will be able to see a page as shown below.
register-an-app
There are three options for supported account types. Ideally, you only need to select “Accounts in any organizational directory” as Chatwoot is generally used for business emails only. However, if you are connecting a personal account, select the second option. If you are using the applications outside your organization, you would need to register your account as a verified publisher.
To configure a redirect URI with the Web platform, use the following URL: https://<your-instance-url>/microsoft/callback. Click on register, and your app will be created. You will see a screen as shown below.
registration-complete
Save the Application (Client) ID. We will configure this as AZURE_APP_ID in Chatwoot later.
​
Configure the application
To ensure proper functionality of Chatwoot, we need to configure the permissions and update the token configuration as follows.
​
API permissions
Click on the “API Permissions” menu under the “Manage” section. By default, this will have User.Read permission.
Click on the “Add permissions” button and add the following permissions from the Delegated permissions menu on Microsoft Graph APIs.
email: To view the user’s email address.
profile: To view the name and picture etc.
offline_access: To retrieve the emails even when you are not using the application.
SMTP.Send, Mail.Send: Send emails using the SMTP AUTH when you reply to customers from the Chatwoot dashboard.
IMAP.AccessAsUser.All, Mail.ReadWrite: Read and write access to mailboxes via IMAP.
openid: Sign users in
permissions
​
Token Configuration
Now, let’s proceed to the Token Configuration to set up “optional claims”. Optional claims are a feature in Entra ID that enables you to specify additional pieces of information (claims) to include in the security tokens issued to the application.
In Chatwoot, we use optional claims to minimize duplicate calls and retrieve some information in advance. Click on “Add optional claim” and add the following claims to the application.
optional-claims.png
​
Configure Client Secret
Go to the Certificates & Secrets section to create a Client Secret. Click on the “New Client Secret” button and provide a description. You can also select an expiry time.
Remember that you will need to regenerate the secret and update it in the Chatwoot environment variables once it expires.
add-client-secret
After clicking on the Add button, a client secret will be generated as shown below.
client-secret-value
Save the value somewhere save as you cannot see it after refreshing the page. This would be used AZURE_APP_SECRET in Chatwoot.
​
Configure environment variables in Chatwoot
After creating the Entra application, you need to configure the application credentials in Chatwoot. There are 2 variables that you need to configure, as shown in the steps above.
AZURE_APP_ID: As seen in the register the app step, use the Application (Client) ID here.
AZURE_APP_SECRET: Use the value obtained in the step configuring the client secret.
After updating the environment variables, restart the Chatwoot service for the changes to take effect. Now, verify if the channel is enabled in the Inbox creation flow. If everything is configured properly, you will see “Microsoft” listed as an email provider in the flow.
microsoft-channel
Voila! That’s it you can now receive the emails in your Chatwoot instance.
​
Thoughts on multi-tenancy and going for production
Note that the setup will not work for other emails under a different tenant until you have completed the Microsoft publisher verification process. During the authorization prompt, you will see “unverified” until the application is verified for production.
To test the changes before the app is verified for production, use the Entra ID app registration email address in the Chatwoot channel.
Publisher verification provides app users and organization admins with information about the authenticity of the developer’s organization that publishes an app integrating with the Microsoft identity platform. If an app has a verified publisher, it means that Microsoft has verified the authenticity of the organization that publishes the app.
Read the publishing guidelines here.
Forwarding Emails to Chatwoot
Guide to set up email forwarding to Chatwoot

This guide explains how to set up email forwarding to Chatwoot when you prefer not to configure IMAP. Forwarding allows your email provider to push inbound messages directly to Chatwoot, which then processes them as incoming conversations in your inbox.
Forwarding emails to Chatwoot requires a cloud storage configured
​
When to Use Forwarding
Forwarding is a good option if:
You don’t want to use IMAP or your provider does not allow IMAP access.
You want a simple, push‑based way to deliver inbound emails to Chatwoot.
Your provider supports routing or forwarding rules (Gmail, Google Workspace, Outlook, Fastmail, Zoho, custom servers, etc.).
You already use SMTP for outbound mail and just need a lightweight inbound setup.
​
How Forwarding Works in Chatwoot
Each email inbox in Chatwoot is assigned an ingress address—a unique, system‑generated email address. When your provider forwards an email to that address, Chatwoot. Note: For installations using an ingress provider (SES, SendGrid, Mailgun, etc.), you must configure an MX record pointing to the ingress provider so that inbound email is accepted and routed correctly.
Ingress provider receives the email and forwards it to the configured Chatwoot URL.
Chatwoot parses the content, attachments, headers, and thread references.
Creates or updates the conversation in the appropriate inbox.
Handles message threading properly via Message-ID, References, and In-Reply-To.
Outbound email continues to use your configured SMTP provider.
​
Requirements
To use forwarding successfully, ensure:
Email ingress is enabled on your Chatwoot installation. Some self-hosted setups disable ingress by default for security.
Your installation supports inbound processing via the configured mailer/ingress pipeline.
The forwarding rule is set to forward all relevant mail, including replies.
SPF, DKIM, and DMARC are correctly configured on your domain for good deliverability.
If ingress is disabled, Chatwoot will show a warning in the UI. Your administrator must enable it before forwarding works.
The receiving domain should be configured in the environment variable MAILER_INBOUND_EMAIL_DOMAIN.
MAILER_INBOUND_EMAIL_DOMAIN=
​
Finding the Forwarding Address
In Chatwoot:
Go to your inbox settings.
Select your email channel settings -> Configuration
Copy the provided Chatwoot ingress email address.
This address is unique per inbox.
​
Configuring Forwarding on Your Email Provider
The setup varies slightly across providers, but the steps are generally:
Open your email provider’s forwarding or routing settings.
Add the Chatwoot ingress email as a forwarding destination.
Verify the address if the provider requires confirmation.
Set a rule to forward all incoming email (or only relevant messages) to the ingress address.
Save the configuration.
​
Configuring Ingress Provider
For Chatwoot installations, a dedicated ingress provider (Amazon SES, SendGrid, Mailgun, etc.) is required. The provider acts as the first receiver of your domain’s email and then forwards it to the Chatwoot ingress URL.
See more details here.
​
Outbound Email Behavior
Forwarding affects only inbound messages. Outbound messages will still be sent using:
The SMTP provider you configured for the inbox (recommended), or
The default SMTP provider configured in the Chatwoot installation.
​
Troubleshooting
Common issues:
​
1. Forwarding Not Enabled in Chatwoot
If you see: “Support for forwarding emails is not configured. Contact your administrator.” Your Chatwoot installation must enable email ingress. MAILER_INBOUND_EMAIL_DOMAIN configuration is missing.
​
2. Emails Not Appearing in the Inbox
Check:
Forwarding rule is enabled and active.
Provider is not suppressing or classifying forwarded mail.
No DMARC quarantine/reject issues.
The ingress address is correct.
​
3. Threading Issues
Chatwoot relies on message headers for threading. Ensure your provider forwards headers intact.
Configuring inbound mails in Chatwoot
Guide to set up inbound emails in Chatwoot

Chatwoot uses Rails Action Mailbox to receive inbound emails. Action Mailbox supports multiple “ingress” providers out of the box, and Chatwoot builds on top of that.
This guide walks you through:
Choosing and configuring an inbound email (ingress) provider
Setting the required environment variables
Using Mailgun, SendGrid, Mandrill, and local relay servers (Exim, Postfix, Qmail, Postmark)
Supported ingress providers today:
Amazon SES
SendGrid
Mandrill
Mailgun
Exim
Postfix
Qmail
Postmark
​
1. Configure the ingress service
First, tell Chatwoot which inbound email service (ingress) you are using. This is done via the RAILS_INBOUND_EMAIL_SERVICE environment variable.
# Set this to the appropriate ingress service. Options:
# "relay"    for Exim, Postfix, Qmail, Postmark
# "mailgun"  for Mailgun
# "mandrill" for Mandrill
# "sendgrid" for SendGrid
# "ses" for Amazon SES
RAILS_INBOUND_EMAIL_SERVICE=relay
This value configures how Action Mailbox will authenticate and route inbound messages into Chatwoot.
​
Using a local relay (Postfix / Exim / Qmail / Postmark)
If you are using a local MTA (for example Postfix) for both inbound relaying and outbound email, and you do not want to use SMTP authentication (SASL) — which is common when the server only handles its own mail — you need to adjust your outbound SMTP configuration.
By default, Action Mailer will try to use SMTP authentication if the following environment variables are present:
SMTP_AUTHENTICATION
SMTP_USERNAME
SMTP_PASSWORD
If you are sending mail through a local relay that does not require authentication:
Remove or comment out these variables from your .env file.
Ensure that your local MTA is correctly configured to send outbound mail.
⚠️ Important: Running your own mail server comes with deliverability and security responsibilities:
Many ISPs block or restrict email servers on their networks.
Configure proper DNS records (SPF, DKIM, DMARC) so that your emails are accepted by recipients and do not land in spam.
​
2. Configure ingress authentication
Next, set the corresponding credentials for the ingress provider you’re using.
# Use one of the following based on the email ingress service

# For SendGrid, Exim, Postfix, Qmail, or Postmark
RAILS_INBOUND_EMAIL_PASSWORD=

# For Mailgun
MAILGUN_INGRESS_SIGNING_KEY=

# For Mandrill
MANDRILL_INGRESS_API_KEY=
Only the relevant variable for your chosen provider needs to be configured.
​
3. Provider-specific configuration
​
Amazon SES
If you are using Amazon SES as your email provider, you have configure the ingress provider as ses and set the ACTION_MAILBOX_SES_SNS_TOPIC to the SNS topic ARN of your SES account.
See more details here.
​
Mailgun
If you are using Mailgun as your email provider:
In your DNS, configure the MX records for your domain to point to Mailgun.
In the Mailgun dashboard, configure routing so that inbound emails are forwarded to:
https://example.com/rails/action_mailbox/mailgun/inbound_emails/mime
Replace example.com with the domain where your Chatwoot installation is hosted.
​
Getting the Mailgun ingress signing key
You can find the signing key in your Mailgun dashboard and set it as MAILGUN_INGRESS_SIGNING_KEY.
mailgun-ingress-key
​
SendGrid
If you are using SendGrid:
Configure MX records for your domain (your-domain.com) to point to SendGrid.
In the SendGrid dashboard, set up Inbound Parse to forward inbound emails to the Action Mailbox endpoint.
Use the following pattern as the Inbound Parse URL:
https://actionmailbox:PASSWORD@example.com/rails/action_mailbox/sendgrid/inbound_emails
Replace PASSWORD with the value of RAILS_INBOUND_EMAIL_PASSWORD.
Replace example.com with your Chatwoot host.
✅ Required: When configuring the SendGrid Inbound Parse webhook, enable the option: “Post the raw, full MIME message”. Action Mailbox must receive the raw MIME message to correctly parse and process the email.
See a detailed guide on how to configure SendGrid Inbound Parse.
​
Mandrill
If you are using Mandrill as your email service:
Configure your domain’s MX records to point to Mandrill.
In the Mandrill dashboard, configure an inbound route that forwards emails to:
https://example.com/rails/action_mailbox/mandrill/inbound_emails
Replace example.com with the domain where your Chatwoot installation is hosted.
Set MANDRILL_INGRESS_API_KEY with the appropriate API key from Mandrill.
​
4. IMAP via getmail
If you already have an IMAP mailbox (for example on your own mail server or with a provider that doesn’t directly support Action Mailbox), you can still feed emails into Chatwoot using getmail6 and the Action Mailbox HTTP ingress.
​
How Action Mailbox ingress works
Action Mailbox exposes HTTP endpoints for each ingress type. They are defined in the Rails source and can also be used directly.
Example using the Rails rake task:
cat my_incoming_message | ./bin/rails action_mailbox:ingress:postfix \
  RAILS_ENV=production \
  URL=http://localhost:3000/rails/action_mailbox/relay/inbound_emails \
  INGRESS_PASSWORD=...
This imports the contents of my_incoming_message (an RFC 822 compliant message) into a Chatwoot instance running on localhost.
​
Calling the HTTP endpoint directly
Instead of using the Rake task, you can call the ingress HTTP endpoint directly via curl.
INGRESS_PASSWORD=...
URL=http://localhost:3000/rails/action_mailbox/relay/inbound_emails

curl -sS -u "actionmailbox:$INGRESS_PASSWORD" \
 -A "Action Mailbox curl relayer" \
 -H "Content-Type: message/rfc822" \
 --data-binary @- \
 $URL
This sends the raw message from stdin to the Action Mailbox relay endpoint.
​
Using getmail6 with IMAP
getmail6 can retrieve emails from an IMAP mailbox and pipe them into the curl script above.
If the script is stored at /home/chatwoot/bin/import_mail_to_chatwoot, a minimal getmail configuration might look like this:
[retriever]
type = SimpleIMAPSSLRetriever
server = ...
username = ...
password = ...

[destination]
type = MDA_external
path = /home/chatwoot/bin/import_mail_to_chatwoot

[options]
verbose = 0
read_all = false
delete = false
delivered_to = false
received = false
message_log = /home/chatwoot/logs/import_imap.log
message_log_syslog = false
message_log_verbose = true
​
Scheduling mail retrieval
To continuously import mail into Chatwoot, you need to run getmail regularly. Common options:
Use cron to run getmail at a fixed interval (for example every minute).
For IMAP, you can use:
getmail --idle INBOX
This keeps a long-lived connection open and reacts to new mail immediately. You’ll need some supervision (systemd, runit, etc.) to handle restarts if the connection is interrupted.
​
5. Further reading
For more details on configuring and customizing ingresses, refer to the official Rails documentation:
Action Mailbox Basics – Configuration
Conversation Continuity
Continue conversations between website live chat and email

When a customer starts a conversation on your website, you don’t want the thread to break just because the user went offline. Chatwoot automatically maintains continuity between the website live chat and email, so the conversation stays in one place for both your agents and your customers.
This guide explains how that flow works and what you should set up to ensure everything stays seamless.
​
How Conversation Continuity Works
​
1. Customer starts a conversation
The customer interacts with your widget and starts a conversation. If Email Collect is enabled, the widget asks the customer for their email address. This email becomes the identifier for all future messages.
​
2. Customer goes offline, agent replies
If the agent replies when the customer is no longer online, Chatwoot delivers the agent’s reply to the customer via email. This ensures the user doesn’t miss the update.
​
3. Customer replies from their email
The user sees your message in their inbox and simply replies to that email like any normal thread. They don’t need to come back to your website manually — replying from email is enough.
​
4. Chatwoot processes the email and links it to the conversation
When Chatwoot receives the user’s email: • It reads the email headers (Message-ID / References / custom thread identifiers) • It maps the email to the correct conversation thread • It adds the user’s reply as a new message inside the same live-chat conversation
To the agent, it looks like the user never left. To the user, it feels like replying to any normal email thread.
​
What You Need to Enable
​
1. Email Collect Hook
Make sure the widget is configured to collect the user’s email early in the conversation. This is the key to linking email replies back to the same thread.
​
2. Email channel configuration
Make sure email forwarding is enabled as per this guide: Forwarding Emails to Chatwoot.
​
3. Mailer configuration
Outbound emails should be properly configured so Chatwoot can notify the customer when the agent replies offline.

After finishing the set up, the mail sent from Chatwoot will have a replyto: in the following format reply+<random-hex>@<your-domain.com> and reply to those would get appended to your conversation.
SendGrid Guide
Guide to setting up Conversation Continuity with SendGrid

This doc will help you set up Conversation continuity with SendGrid.
​
Installation
This example is based on a Heroku installation of Chatwoot, and using SendGrid for outgoing email. For more information about installing Chatwoot, go here.
​
Configuring inbound reply emails
Firstly, we need to tell our Chatwoot instance what mailer we’re using to handle incoming emails. We do that with a config var. Go to your Heroku dashboard, click on your Chatwoot instance and click settings.
Screenshot_95
Then scroll until you see two blank fields with an add button. There, enter:
RAILS_INBOUND_EMAIL_SERVICE=sendgrid
Screenshot_96
Next, we’re going to set a password. We’ll use this later on with SendGrid. For this example, we’ll use something simple - like potatosalad, but like all passwords - you should always use a secure mixture of letters, numbers and symbols.
Screenshot_97
​
SendGrid
Now we’re going to set up the domain we’re using for inbound emails. Because you’re most likely going to have an email service like Google Workspace or Microsoft 365 for Business, you should use a subdomain for your inbound emails to Chatwoot.
For example, let’s say we used support.example.com as our domain. In this instance, we’d add an MX record pointing support.example.com to mx.sendgrid.net with a priority of 10.
You should wait a while (usually an hour will do). You can use mxtoolbox.com to check if the MX record has been propogated. If you see something like this, you can move onto the next step:
Screenshot_98
Now, go to the SendGrid dashboard at app.sendgrid.com. Select Settings, and Inbound Parse.
Screenshot_99
Then click “Add Host & URL”.
Screenshot_100
Receiving Subdomain should be the domain you set up the MX record for earlier.
Screenshot_101
Then add your Destination URL. Your Destination URL should look something like this:
https://actionmailbox:potatosalad@chatwoot.example.com/rails/action_mailbox/sendgrid/inbound_emails
potatosalad is the password we set earlier, and chatwoot.example.com is the URL of our Chatwoot instance. Everything else should stay the same.
Screenshot_102
Make sure to check “POST the raw, full MIME message”. In order to function correctly, Action Mailbox needs the raw MIME message.
Screenshot_103
​
Setting the inbound domain variable in Heroku
Finally, we need to tell our Chatwoot installation what domain we’re using with SendGrid.
Your variable should look like this:
MAILER_INBOUND_EMAIL_DOMAIN=support.example.com
You should change support.example.com to the domain you used with SendGrid.
Screenshot_104
​
Next steps
You’re done! Next, you should enable the email channel.
Configuring Amazon SES as an Ingress Provider for Chatwoot
Guide to setting up conversation continuity, inbound emails with Amazon SES

This guide explains how to set up Amazon SES as the incoming email (ingress) provider for your self-hosted Chatwoot installation. If you plan to use Chatwoot’s email forwarding option and want SES to handle inbound mail delivery into Chatwoot, this documentation is for you.
​
Who is this for?
This setup is intended for:
Teams running self‑hosted Chatwoot.
Users who want to use Amazon SES to receive inbound emails.
Workspaces that want to configure forwarding rules rather than using IMAP/OAuth connections to bring emails into Chatwoot.
If you are using Chatwoot Cloud, you do not need this setup.
​
Architecture
At a high level, the flow looks like this:
Architecture
An email is sent to your domain (e.g., support@yourdomain.com).
Amazon SES receives the email.
SES forwards the message to an SNS Topic.
SNS publishes the message payload to a Chatwoot email ingress endpoint.
Chatwoot processes the payload and creates/updates a conversation.
​
Prerequisites
Before you begin, you should have:
Access to AWS SES, SNS, Route53 (or your DNS provider).
A self‑hosted Chatwoot installation reachable over HTTPS.
​
Step 1: Verify Your Domain in Amazon SES
Amazon SES must verify that you own the domain before it can receive mail.
Log in to AWS Console → SES → Identities.
Click Create Identity.
Choose Domain.
Enter the domain you want to receive email for.
Amazon SES will show DNS records you must add:
DKIM (CNAME) records
SPF (TXT) record
DMARC (TXT) record (optional but recommended)
Add all records to your DNS provider.
Wait for the identity status to become verified.
​
Step 2: Configure MX Records to Route Email to SES
SES must become the inbound email handler for your domain.
In SES, open Configuration → Email Receiving.
Locate the MX record value for your region (example: 10 inbound-smtp.us-east-1.amazonaws.com).
Go to your DNS provider.
Add an MX record:
Priority: 10
Value: inbound-smtp.<region>.amazonaws.com
Once this is set, your domain will start routing incoming mail to SES. If you have any doubts about setting this up, read more at AWS SES documentation.
​
Step 3: Configure SES to Publish Inbound Emails to SNS
Chatwoot reads incoming messages via SNS notifications.
Go to SES → Email Receiving → Rule Sets.
SES Email Receiving
Create a Rule Set if you don’t have one.
SES Rule Sets
Add a new rule:
Recipients → Add your inbound email (e.g. support@yourdomain.com) or ignore this field since it would forward every email to SNS (which is better if you have more than one email channel)
Actions → Publish to Amazon SNS topic
Select your SNS topic.
Make sure that you select the Encoding as UTF-8.
SES Publish to SNS
Save and enable the rule.
Note: You don’t have to turn on Transport Layer Security (TLS) or Spam and virus scanning for this setup. Now SES will publish every inbound email event to your SNS topic.
​
Step 4: Configure Chatwoot Environment Variables
Before creating the SNS subscription, you must configure two environment variables in your Chatwoot installation:
RAILS_INBOUND_EMAIL_SERVICE=ses

# SNS topic ARN for ActionMailbox (format: arn:aws:sns:region:account-id:topic-name)
# Configure only after you create the SNS topic in AWS
ACTION_MAILBOX_SES_SNS_TOPIC=
Why this matters: Chatwoot needs to know that SES will be used for inbound email. Chatwoot must be ready to valid the SNS topic once the subscription is created.
​
Step 5: Create SNS Subscription to Forward to Chatwoot
SNS needs to send the email payload directly to Chatwoot.
Go to SNS → Topics. Open the topic you created. Click Create Subscription.
SES Create Subscription
Set:
Protocol: HTTPS
Endpoint: Your Chatwoot email ingress endpoint https://chatwoot.example.com/rails/action_mailbox/ses/inbound_emails
SES Create Subscription
Save.
Note: SNS will send a confirmation request. Chatwoot will automatically confirm the subscription.
​
Step 6: Add Email Channel in Chatwoot
Go to your Chatwoot account. Settings → Inboxes → Add Inbox.
Choose Email -> Other Providers.
Use any email address from the domain that is configured in SES.
After this you should see incoming email in your inbox.
​
Troubleshooting
Emails not appearing in Chatwoot:
Check SES → SNS → Subscription delivery logs.
Check SNS subscription status.
Check Chatwoot logs for any errors.
Ensure Chatwoot server is reachable publicly.
Check if MX records propagated.
SNS subscription not confirmed:
Ensure Chatwoot server is reachable publicly.
Verify system time and SSL certificates on your server. If you are testing this in local environment, you can use tools like ngrok to expose your Chatwoot server to the internet. Make sure that you are using openssl<=3.5.
Help Center
Help Center
Set up a public-facing help center portal with custom domain and SSL certificate

Help center allows you to create a portal and add articles from the chatwoot app dashboard. You can point to these help center portal articles from your main site and display them as your public-facing help center.
​
How to get SSL certificate for your custom domain
​
Create a Portal in Chatwoot’s dashboard
Follow these step to create your Portal. Refer to this guide.
​
Point your custom domain to your Chatwoot domain
Go to your DNS provider and add a new CNAME record.
For the above example, add docs as a CNAME record and point it to the your selfhosted chatwoot domain(FRONTEND_URL).
This will ensure that your CNAME record points to the selfhosted Chatwoot installation. For your custom domain, we have your portal information. In this case, docs.example.com
​
Setting up SSL
Use certbot to generate SSL certificates for your custom domain.
certbot certonly --agree-tos --nginx -d "docs.example.com"
Create a new nginx config to route requests to this domain to Chatwoot. Make a copy of /etc/nginx/sites-available/nginx_chatwoot.conf and make necessary changes for the new domain.
Restart nginx server.
sudo systemctl restart nginx
Voila!
docs.yourdomain.com is live with a secure connection, and your portal data is visible.
​
How does this work?
These are the engineering details to understand How does docs.yourdomain.com gets the portal data with SSL certificate.
docs.yourdomain.com resolves by customers nameserver and redirects to your Chatwoot domain.
Chatwoot check for the portal record with custom-domain docs.yourdomain.com
Redirects to the portal records for the domain docs.yourdomain.com
Yaay!!
Now you can have your own help-center, product-documentation related portal saved at Chatwoot dashboard and served at your domain with SSL certificate.
Integrations
Setting Up Facebook
Configure Facebook Messenger integration for Chatwoot

To use Facebook Channel, you have to create a Facebook app in the developer portal. You can find more details about creating Facebook apps here.
​
Prerequisites
A valid facebook account.
A valid facebook page.
​
Register A Facebook App
Go to Facebook developer portal and click on the “Create App” button
facebook_create_app
Select the option “Other”.
facebook_other_app
For the app type, choose “Business”.
facebook_business
Enter basic details like the app name and email.
facebook_business_details
Once you register your Facebook App, you will have to obtain the App Id and App Secret. These values will be available in the app settings and will be required while setting up Chatwoot environment variables.
facebook_app_id
​
Configuring the Environment Variables in Chatwoot
Configure the following Chatwoot environment variables with the values you obtained during the Facebook app setup. The FB_VERIFY_TOKEN should be a unique and secure string that you provide when configuring the Facebook app. Generate a random string and set it as the FB_VERIFY_TOKEN. Facebook will include this string in all verification requests.
Restart the Chatwoot server after updating the environment variables
FB_VERIFY_TOKEN=
FB_APP_SECRET=
FB_APP_ID=
​
Configure Facebook Login
Add the Facebook Login product via the Facebook app dashboard.
facebook_app_login
Enable Web OAuth Login, Login with Javascript SDK and add your self-hosted domain to the Allowed Domains for the JavaScript SDK input.
facebook_sdk_login
​
Configure the Facebook App
In the app settings, add your Chatwoot installation domain as your app domain.
facebook_app_domain
In the products section in your app settings page, Add “Messenger”
facebook_messenger_product
Go to the Messenger settings and configure the call back URL
Alt text
Provide the Callback URL as {your_chatwoot_installation_url}/bot and the Verify token as FB_VERIFY_TOKEN from your environment variable.
facebook_callback_url
Head over to Chatwoot and create a Messenger inbox. Choose a page for which your Facebook developer account has admin access to. Please refer to this guide for more details on creating a Messenger inbox in Chatwoot.
​
Testing the Facebook channel
Until the application is approved for production, Facebook wouldn’t send the new messages on your page to Chatwoot.
To test the changes until the app is approved for production. Follow the steps
Head over to the messenger section in your app settings page, in Facebook developers.
facebook_messenger_settings
Click Add or remove pages and connect the page which you choose while creating the Chatwoot Messenger inbox.
facebook_callback_pages
After connecting the pages, Click on Add subscriptions from the connected page.
facebook_page_config
Subscribe to the following fields and save the subscription.
messages
messaging_postbacks
message_deliveries
message_reads
message_echoes
facebook_page_subscription
Send a message to the connected page from your Facebook account and it should appear in Chatwoot now.
​
Going into production.
Before you can start using your Facebook app in production, you will have to get it verified by Facebook. Refer to the docs on getting your app verified.
Obtain advanced access to the required permissions mentioned below for your Facebook app
pages_messaging (To message on behalf of the page)
pages_show_list (To list the pages to be connected in chatwoot)
pages_manage_metadata (Subscribe webhooks on behalf of the page)
business_management
pages_read_engagement (Read followers data (including name, PSID), and profile )
Business Asset User Profile Access  (For accessing user profile picture and name of people who contacts the page)
Make sure your facebook app subscription version is 17.0, we have updated the FB subscription with the latest version, so change the permission subscription version under the facebook app webhooks option.
​
Developing or Testing Facebook Integration in your machine
Install ngrok on your machine. This will be required since Facebook Messenger API’s will only communicate via https.
brew cask install ngrok
Configure ngrok to route to your Rails server port.
ngrok http 3000
Go to the Facebook developers page and navigate into your app settings. In the app settings, add localhost as your app domain. In the Messenger settings page, configure the callback url with the following value.
{your_ngrok_url}/bot
Update verify token in your Chatwoot environment variables.
You will also have to add a Facebook page to your Access Tokens section in your Messenger settings page. Restart the Chatwoot local server. Your Chatwoot setup will be ready to receive Facebook messages.
​
Facebook API version
We support facebook API version v13.0 going forward, which you can update in the facebook app advanced settings.
fb_api_version
​
Test your local Setup
After finishing the set-up above, create a Facebook inbox after logging in to your Chatwoot Installation.
Send a message to your page from Facebook.
Wait and confirm incoming requests to /bot endpoint in your ngrok screen.
Previous

Instagram via Facebook Login
Set up Instagram integration using Facebook Login authentication

We recommend Instagram Business Login as the preferred authentication method, as it provides simpler configuration and a better developer experience. Please refer to this guide for more details. We will be stopping the support for Instagram via Facebook Login in the future from v4.1 onwards.
​
Prerequisites
A valid facebook account.
A valid facebook page.
A valid instagram professional account.
​
Register A Facebook App
To use Instagram Channel, you have to create a Facebook app in the developer portal. You can find more details about creating Facebook developer app here.
Click on the “Create App” button
facebook_create_app
Select the option “Other”.
facebook_other_app
For the app type, choose “Business”
facebook_business
Enter basic details like the app name and email.
facebook_business_details
Once you register your Facebook App, you will have to obtain the App Id and App Secret. These values will be available in the app settings and will be required while setting up Chatwoot environment variables.
facebook_app_id
​
Configuring the Environment Variables in Chatwoot
Configure the following Chatwoot environment variables with the values you obtained during the Facebook app setup. The IG_VERIFY_TOKEN should be a unique and secure string that you provide when configuring the Instagram app.
Restart the Chatwoot server after updating the environment variables
IG_VERIFY_TOKEN=
FB_APP_SECRET=
FB_APP_ID=
​
Configure the Facebook App
In the app settings, add your “Chatwoot installation domain” as your app domain.facebook_app_domain
Add the “Instagram Graph API” product via the Facebook app dashboard.instagram_product
Go to the app settings and select “Webhooks”. From there, choose Instagram and click on the “Subscribe to this object” button.instagram_webhooks
Provide the Callback URL as {your_Chatwoot_installation_url}/webhooks/instagram and the Verify token as IG_VERIFY_TOKEN from your environment variable.instagram_webhook_url
​
Connect the facebook page with instagram account
Go to Facebook pages and select your page and open the settings
facebook_page_settings
Go to “Linked accounts” and connect your instagram professional account.
facebook_connect_instagram
Select the option “Business”instagram_connect_facebook
Select the instgram account category
select_category_instagram
If everything is okay, you will see the message “Instagram connected.”
instagram_connect_success
​
Create Instagram Inbox in Chatwoot
Head over to Chatwoot and create a Messenger inbox. Please refer to this guide for more details on creating a Messenger inbox in Chatwoot.
So whenever you receive any message on Instagram, it will redirect to your Facebook page.
​
Testing the Instagram channel
Until the application is approved for production, Facebook wouldn’t send the new messages on your instagram to Chatwoot. To test the changes until the app is approved for production. Follow the steps
Create a Test app for your app.
facebook_instagram_test
Add the Instagram Graph API product via the Facebook app dashboard.instagram_product
Go to the app settings and select “Webhooks”. From there, choose Instagram and click on the “Subscribe to this object” button.instagram_webhooks
Provide the Callback URL as {your_chatwoot_installation_url}/webhooks/instagram and the Verify token as IG_VERIFY_TOKEN from your environment variable.instagram_webhook_url
Open the test app and add extra product for the test app: Instagram Basic Display
instagram_basic_display
In the app settings, add the platform “Website” and give Site URL as your installation URL.
instagram_app_platform
Head over to the Instagram Basic Display section and create a new app.
instagram_basic_display_settings
Add Instagram Testers by clicking “Add or Remove Instagram Testers” button.
instagram_testers
Make sure that you have selected the role Instagram Tester while creating a new tester.
instagram_tester_list
Click on Edit subscriptions under Webhook > Instagram and subscribe to the following,
message_reactions
messages
messaging_seen
instagram_subscription
You should do this step for both normal and test apps.
Head over to Chatwoot and create a Messenger inbox. Please refer to this guide for more details on creating a Messenger inbox in Chatwoot.
Send a message to the connected Instagram account from Instagram Testers, and it should appear in Chatwoot now
​
Going into production.
Before you can start using your Facebook app in production, you will have to get it verified by Facebook. Refer to the docs on getting your app verified.
Obtain advanced access to the required permissions mentioned below for your Facebook app
instagram_manage_messages
instagram_basic
pages_show_list (To list the pages to be connected in chatwoot)
pages_manage_metadata (Subscribe webhooks on behalf of the page)
pages_messaging (To message on behalf of the page)
business_management (For accessing user profile picture and name of people who contacts the page)
If your facebook app’s version is more than 7.0 then you will need extra permission according to facebook’s updated policy. Make sure you get permission for.
pages_read_engagement
​
Developing or Testing Facebook Integration in your machine
Install ngrok on your machine. This will be required since Facebook Messenger APIs will only communicate via https.
brew cask install ngrok
Configure ngrok to route to your Rails server port.
ngrok http 3000
Go to the Facebook developers page and navigate into your app settings. Add localhost as your app domain and add a privacy policy URL in the app settings. In the Webhook > Instagram settings shown in the above image, configure the callback url with the following value.
{your_ngrok_url}/webhooks/instagram
Update verify token in your Chatwoot environment variables.
You will also have to add a Facebook page to your Access Tokens section in your Messenger settings page. Restart the Chatwoot local server. Then, your Chatwoot setup will be ready to receive Facebook messages.
​
Test your local Setup
After finishing the setup above, create a Messenger inbox after logging in to your Chatwoot Installation.
Send a message to your Facebook Page from your Instagram account.
Wait and confirm incoming requests to /webhooks/instagram endpoint in your ngrok screen.
You can also verify your callback URL by clicking on Test for the subscribed Instagram fields. Go to webhook Instagram and click on Test with v11.0subscribe
You can have only one app connected to the Chatwoot for Instagram and Facebook combined as the Messenger platform is common. But suppose you want to have separate channels for Instagram and Facebook. In that case, you can have multiple Facebook pages inside your app that would be connected to Facebook users and Instagram users separately and then connected to the different inbox in the Chatwoot page.
​
Checklist
Integrate the Facebook test app and Send a message from the Instagram tester to the connected account.
Make sure your Instagram account is a business account.
If the Instagram test account can receive the message and forward it to the webhook URL, then submit it for review.
If the Instagram test account is not able to receive the message and forward it to the webhook URL
Check the logs if you are receiving the message to {your-app-url}/webhooks/Instagram
If the logs are present for the above endpoint, if there are any errors, then reach out to us. We will help you out.
If the logs aren’t present for the above endpoint, then raise a bug for the Facebook team or follow this bug https://developers.facebook.com/support/bugs/468852858104743/
If you are not facing the above issue and can get the message, but the review isn’t passing, then reach out to the reviewer.
When your app gets rejected, open the rejected submission. You can see the messenger icon in the bottom right corner to support you with your rejected review.
You can talk to the support team and ask your questions about the submission and the reason for the rejection.
If your test app passed the review, it’s good to go into production.
If you face an issue on production that you cannot receive the messages, then reach out to us with the error logs.
Integrations
Instagram via Instagram Business Login
Set up Instagram integration using Instagram Business Login authentication (recommended method)

Please ensure you have installed version v4.1 or above. If not, please refer to this guide for the Facebook Login method.
​
Prerequisites
A valid facebook account.
A valid instagram professional account.
​
Register A Facebook App
To use Instagram Channel, you have to create a Facebook app in the developer portal. You can find more details about creating Facebook apps here.
Click on the “Create App” button
facebook_create_app
Select the option “Other”.
facebook_other_app
For the app type, choose “Business”
facebook_business
Add app name and connect business account
facebook_business_details
Add Instagram product from the Home page.
instagram_product
​
Configure Instagram settings for Chatwoot
Copy Instagram app ID and Instagram app secret
instagram_app_id
Add the Instagram app ID and Instagram app secret to your app config via {Chatwoot installation url}/super_admin/app_config?config=instagram
instagram_app_config
Configure Webhooks
Set the callback URL to {your_chatwoot_url}/webhooks/instagram. The verify token should match your INSTAGRAM_VERIFY_TOKEN, which can be configured through app_config
instagram_webhooks
Subscribe to messages, messaging_seen, and message_reactions events.
instagram_webhooks_subscribe
To receive web hooks, app mode should be set to “Live”.
Set up Instagram business login
Set Redirect URL as {your_chatwoot_url}/instagram/callback
instagram_business_login
Create a new Instagram tester account
​
Create Instagram Inbox
Head over to Chatwoot and create a Instagram inbox. Please refer to this guide for more details on creating a Instagram inbox in Chatwoot.
​
How to test the Instagram before going to live
Add Instagram Testers by clicking “Add People” button.
facebook_instagram_test
Make sure that you have selected the role Instagram Tester while creating a new tester.
instagram_tester_list
​
Going into production.
Before you can start using your Facebook app in production, you will have to get it verified by Facebook. Refer to the docs on getting your app verified.
​
Troubleshooting & Common Errors
​
Insufficient Developer Role Error
Ensure the Instagram user is added as a developer: Meta Dashboard → App Roles → Roles → Add People → Enter Instagram ID
​
API Access Deactivated
Ensure the Privacy Policy URL is valid and correctly set.
​
Invalid request: Request parameters are invalid: Invalid redirect_uri
Please configure the Frontend URL. The Frontend URL does not match the authorization URL.
​
Instagram Channel creation Error: Failed to exchange token
Please make sure that tester account has been added to the facebook app settings.
​
400: Session Invalid when connecting the instagram channel
This might be issue from facebook side. Please try again after some time.
Previous
WhatsApp Embedded Signup
Set up WhatsApp integration using Meta's streamlined embedded signup flow
Next
twitte

Integrations
WhatsApp Embedded Signup
Set up WhatsApp integration using Meta’s streamlined embedded signup flow

WhatsApp Embedded Signup enables users to connect their WhatsApp Business accounts through Meta’s streamlined OAuth flow without manual webhook configuration. This significantly improves the user experience by automating the entire setup process.
​
Prerequisites
A valid Facebook account
A WhatsApp Business account (or ability to create one)
Admin access to your Chatwoot installation
​
Super Admin Configuration
Before users can use WhatsApp Embedded Signup, administrators must configure the following environment variables via the Super Admin panel at /super_admin/app_config?config=whatsapp_embedded:
WHATSAPP_APP_ID: The Facebook App ID for WhatsApp Business API integration
WHATSAPP_CONFIGURATION_ID: The Configuration ID for WhatsApp Embedded Signup flow (obtained from Meta Developer Portal)
WHATSAPP_APP_SECRET: The App Secret for WhatsApp Embedded Signup flow (required for token exchange)
These settings must be configured by a Super Admin before the WhatsApp Embedded Signup option becomes available to users.
​
Retrieving Configuration Values from Meta Developer Portal
To obtain the required configuration values:
​
1. Create or Access Your Facebook App
Go to Meta for Developers
Click on “My Apps” in the top navigation
Either select an existing app or click “Create App”
If creating a new app:
Choose “Business” as the app type
Select “Business” for “I want to connect my app to”
Provide app details (name, email, business portfolio)
​
2. Configure WhatsApp Product
In your app dashboard, click “Add Product”
Find “WhatsApp” and click “Set Up”
Accept the WhatsApp Business Terms
​
3. Retrieve App ID and App Secret
App ID: Found at the top of your app dashboard or in Settings → Basic
App Secret: Located in Settings → Basic (click “Show” and authenticate to reveal)
​
4. Obtain Configuration ID
Navigate to Facebook Login for Business → Configuration in the left sidebar
Click “Configurations”
Set up the configuration:
Select login variation to: WhatsApp Embedded Signup.
Select WhatsApp Account as an assets. (Give manage account permission)
Add required permissions. Mentioned below
Save the configuration
Copy the generated Configuration ID
Important: Before overriding the current callback URI, your app must be subscribed to receive messages for the WhatsApp Business Account. This prevents error (#100) during webhook configuration. Ensure the messages webhook field is subscribed in your app’s webhook settings.
​
5. Required Permissions
Ensure your app has the following permissions enabled:
whatsapp_business_management - Manage WhatsApp business assets
whatsapp_business_messaging - Send and receive WhatsApp messages
business_management - Manage business assets
For production use, your app may need to go through App Review to get advanced access to certain features. The embedded signup flow works with Standard Access for most use cases.
​
Creating a WhatsApp Channel
​
Step 1: Navigate to Channel Selection
Go to Settings → Inboxes in your Chatwoot dashboard
Click on “Add Inbox”
Select WhatsApp from the channel options
whatsapp_channel_selection
​
Step 2: Choose WhatsApp Cloud
Select “WhatsApp Cloud” for the quick setup through Meta (embedded signup).
whatsapp_provider_selection
​
Step 3: Start Embedded Signup
Click on “Connect with WhatsApp Business” to begin the embedded signup flow.
whatsapp_embedded_signup_start
​
Step 4: Facebook Authentication
You’ll be redirected to Facebook to authenticate. You need to log in with an existing Facebook account.
whatsapp_facebook_authentication
​
Step 5: Fill Business Information
Select an existing business portfolio or create a new one to add your phone number. Fill in the required business information:
Business portfolio
Business name
Business website or profile page
Country
Address (optional)
whatsapp_business_information
​
Step 6: Select WhatsApp Business Account
Choose an existing WhatsApp Business account or create a new one. You can also select or create a WhatsApp Business Profile.
whatsapp_account_selection
​
Step 7: Complete Setup
Once you’ve completed all steps, you’ll see the success screen. Your WhatsApp Business account is now connected and ready to receive messages.
whatsapp_setup_completewhatsapp_app_config
​
Key Features
No manual configuration required: The entire webhook and phone number setup is automated
Secure OAuth based authentication: Uses Meta’s official OAuth 2.0 flow
Automatic webhook and phone number configuration: Webhooks are registered automatically
Real-time progress tracking: Visual feedback during the signup process
Comprehensive error handling: Clear error messages and guidance
​
Commerce Policy Compliance
Meta will review your business to ensure it complies with WhatsApp’s Commerce Policy and will reach out within 24 hours if there’s an issue.
​
Reference Documentation
For more technical details about WhatsApp Embedded Signup, refer to the official Meta documentation:
WhatsApp Embedded Signup - Meta for Developers
​
Troubleshooting
​
Common Issues
“WhatsApp Embedded Signup not available”
Ensure your Super Admin has configured the required environment variables
Check that all three values (App ID, Configuration ID, and App Secret) are properly set
Authentication Errors
Make sure you’re using an existing Facebook account
Verify you have the necessary permissions for the business
Business Verification Issues
Ensure your business information is accurate and complete
Check that your business complies with WhatsApp’s Commerce Policy
​
Getting Help
If you encounter issues during setup:
Check the Chatwoot logs for any error messages
Verify all environment variables are correctly configured
Ensure your Facebook/WhatsApp accounts meet the prerequisites
Contact Chatwoot support with specific error messages if the issue persists

Setting Up Slack Integration
Configure Slack integration to receive Chatwoot conversations in Slack channels

Setting up Chatwoot Slack integration involves 5 steps.
Create a slack app in the developer portal.
Add necessary permissions for the slack app.
Configure Chatwoot with the client ID and client Secret obtained from the slack app.
Open Chatwoot UI, navigate to integrations, Slack and click connect.
Voila! You should be receiving new conversations in the #customer-conversations channel in Slack.
​
Register a Slack app
To use Slack Integration, you have to create a Slack app in the developer portal. You can find more details about creating Slack apps at the Slack developer portal.
Once you register your Slack App, you will have to obtain the Client Id and Client Secret. These values will be available in the app settings and will be required while setting up Chatwoot environment variables.
​
Configure the Slack app
Create a Slack app and add it to your development workspace.
Obtain the Client Id and Client Secret for the app and configure it in your Chatwoot environment variables.
Head over to the OAuth & permissions section under features tab.
In the redirect URLs, Add your Chatwoot installation base URL.
In the scopes section configure the given scopes for bot token scopes:
channels:history
channels:join
channels:manage
channels:read
chat:write
chat:write.customize
commands
files:read
files:write
groups:history
groups:write
im:history
im:write
links:read
links:write
mpim:history
mpim:write
users:read
users:read.email
In the user access token section subscribe to: files:read, files:write, remote_files:share
Head over to the Events Subscriptions section in the Features tab.
Enable events and configure the given request url {Chatwoot installation url}/api/v1/integrations/webhooks
Subscribe to the following bot events: link_shared, message.channels, message.groups, message.im, message.mpim.
Add the installation URL as domain under the App unfurl domains section to display meta information about the conversation when the conversation URL is shared.
Connect Slack integration on Chatwoot app and get productive.
​
Configure the environment variables in Chatwoot
Obtain the Client ID and Client Secret for the app and configure it in your Chatwoot environment variables.These values will be available under Settings > Basic Information.
SLACK_CLIENT_ID=
SLACK_CLIENT_SECRET=
Restart the Chatwoot server.
Slack will only show up in the integrations section once you have configured these values and restarted the server.
​
Connect Chatwoot with your Slack workspace
Follow this guide to complete the Slack integration.
​
Testing your setup
Create a new conversation.
Ensure that you are receiving the Chatwoot messages in the connected slack channel.
Add a message to that thread and ensure that it is coming back on to Chatwoot.
Add note: or private: in front of the Slack message to see if it is coming out as private notes.
If your Slack member’s email matches their email on Chatwoot, the messages will be associated with their Chatwoot user account.
Previous
Linear
Setting Up TikTok Channel
Configure TikTok Business Messaging integration to manage TikTok conversations from Chatwoot

The TikTok channel integration enables you to manage TikTok Business Messaging conversations directly from Chatwoot. Agents can receive and reply to messages from TikTok users, view shared posts, and handle image attachments -all within the Chatwoot dashboard.
Setting up the TikTok channel involves 7 steps.
Create a TikTok Developer Account.
Register an app in the TikTok Developer Portal.
Apply for Business Messaging API access.
Configure app permissions and redirect URLs.
Configure Chatwoot with the App ID and App Secret obtained from TikTok.
Set up the webhook for incoming messages.
Connect a TikTok Business Account from the Chatwoot dashboard.
​
Prerequisites
A self-hosted Chatwoot instance accessible via a public HTTPS URL
A TikTok Business Account registered in an eligible region
Your TikTok Business Account must be set to accept direct messages from everyone. Otherwise, you will need to manually accept messages in the TikTok app. Learn how to update your message settings.
A TikTok Developer Account at developers.tiktok.com
Access to the TikTok Business Messaging API (requires special permissions and approval)
Super Admin access to your Chatwoot instance
The TikTok Business Messaging API is region-restricted. It is currently unavailable for accounts registered in the European Economic Area (EEA), Switzerland, or the United Kingdom. Personal TikTok accounts are not supported -only TikTok Business Accounts can use this integration.
​
Step 1: Create a TikTok Developer Account
Go to developers.tiktok.com and sign up
Verify your email address
Accept the Terms of Service
​
Step 2: Register Your App
create_tiktok
Go to business-api.tiktok.com/portal/apps and create a new app
Fill in the required fields:
App Name: e.g., “Your Company - Chatwoot”
App Description: Brief description of your messaging use case
App Icon: Upload your company logo
Terms of Service URL: Your company’s ToS URL
Privacy Policy URL: Your company’s privacy policy URL
Once created, note down your App ID (client key) and App Secret (client secret)
​
Step 3: Apply for Business Messaging API Access
You need to grant your app access to the Business Messaging API. For detailed instructions, refer to the TikTok Business Messaging API access guide.
Open your app in the TikTok Developer Portal
Navigate to the Business Messaging API product
Submit an application with:
Your use case (e.g., customer support via Chatwoot)
How you will handle user data
Your organization details
Wait for TikTok’s review and approval
Approval typically takes a few days but can take longer for specialized access. You cannot proceed with the integration until your application is approved.
​
Step 4: Configure App Permissions and URLs
Once approved, configure the following in the TikTok Developer Portal.
​
Required Permissions
After your app is approved, ensure the TikTok Accounts permission is enabled under Scope of permission in your app settings.
tiktok-accounts-permission
​
Authorization Redirect URL
Set the authorization redirect URL to:
{Chatwoot installation url}/tiktok/callback
​
Step 5: Configure Chatwoot
​
Super Admin Configuration
Log in to your Chatwoot instance as a Super Admin
Navigate to {Chatwoot installation url}/super_admin/app_config?config=tiktok
Enter your TikTok App ID and TikTok App Secret
Click Submit
Alternatively, you can set these as environment variables:
TIKTOK_APP_ID=your_tiktok_app_id
TIKTOK_APP_SECRET=your_tiktok_app_secret
Restart the Chatwoot server after making changes.
​
Enable TikTok Feature
In Super Admin, navigate to Accounts
Select the account where you want to enable TikTok
Under Features, enable the TikTok channel
Save the changes
TikTok will only show up in the inbox channel options once you have configured the App ID and App Secret and enabled the feature for the account.
​
Step 6: Configure Webhook
Set up the TikTok webhook to receive incoming messages. Open a Rails console on your Chatwoot server:
bundle exec rails console
Run the following command to register the webhook callback URL:
Tiktok::AuthClient.update_webhook_callback
This sets the webhook URL to {Chatwoot installation url}/webhooks/tiktok.
You can verify the webhook configuration by running:
Tiktok::AuthClient.webhook_callback
The webhook must be configured after setting the TikTok App ID and App Secret in Super Admin. If you change your Chatwoot domain, you will need to run this command again.
​
Step 7: Connect Chatwoot with Your TikTok Account
Follow the TikTok channel user guide to complete the TikTok integration.
​
Troubleshooting
​
TikTok channel not appearing in inbox options
Verify the TikTok feature is enabled for the account in Super Admin
Confirm TIKTOK_APP_ID and TIKTOK_APP_SECRET are set correctly
Restart the Chatwoot server after configuration changes
​
OAuth authorization fails
Ensure the redirect URL in the TikTok Developer Portal exactly matches {Chatwoot installation url}/tiktok/callback
Verify your TikTok app has all required scopes enabled
Check that your TikTok app is approved for the Business Messaging API
​
Not receiving incoming messages
Verify the webhook is configured by running Tiktok::AuthClient.webhook_callback in Rails console
Ensure the webhook URL is publicly accessible over HTTPS
Check that your TikTok Business Account is in an eligible region
Review Sidekiq logs for Webhooks::TiktokEventsJob errors
​
Messages failing to send
Check if the 48-hour reply window has expired
Verify the access token is valid -Chatwoot automatically refreshes tokens, but if the refresh token expires (30 days), the channel will need reauthorization
Ensure you are sending a supported message type (text only, or a single image)
Check Sidekiq logs for SendReplyJob errors
​
Channel shows “Reauthorization Required”
This happens when both the access token (around 24 hours) and refresh token (around 30 days) have expired, typically due to inactivity.
Go to Settings → Inboxes → select the TikTok inbox
Click Reauthorize
Complete the TikTok OAuth flow again
​
Webhook signature verification fails
Ensure TIKTOK_APP_SECRET matches the secret in your TikTok Developer Portal
Check server clock synchronization -TikTok’s signature verification requires timestamps within 5 seconds
Upgrading your Chatwoot installation
Step-by-step guide to upgrade Chatwoot across different deployment methods

​
Linux VM
Whenever a new version of Chatwoot is released, use the following steps to upgrade your instance.
To install cwctl, refer this section below.
If you are on an older version of Chatwoot(< 2.7), follow the manual upgrade steps if you face errors with cwctl.
cwctl --upgrade
This upgrade method is applicable for all manual linux installations including installation using aws marketplace.
​
Docker
Update the images using the latest image from chatwoot.
docker-compose down
docker-compose pull
docker-compose up -d
Run the rails db:chatwoot_prepare option after accessing the console from one of the containers running the latest image.
docker exec -it $(basename $(pwd))-rails-1 sh -c 'RAILS_ENV=production bundle exec rails db:chatwoot_prepare'
​
Helm(Kubernetes)
This upgrade guide is applicable for Chatwoot DigitalOcean 1-click k8s app and any other Kubernetes deployment using charts.
Do helm repo update and check the version of charts that is going to be installed. Helm charts follows semantic versioning and so if the MAJOR version is different from your installed version, there might be breaking changes. Please refer to the changelog before upgrading.
# update helm repositories
helm repo update
# list your current installed version
helm list
# show the latest version of charts that is going to be installed
helm search repo chatwoot
#if it is major version update, refer to the changelog before proceeding
helm upgrade chatwoot chatwoot/chatwoot -f <your-custom-values>.yaml
​
Heroku
Pull the latest changes from Chatwoot github repo to your fork. Use the fetch upstream changes feature on Github.
Deploy the latest branch to your heroku app.
Backing Up Your Chatwoot Installation
Complete guide to backing up and restoring your Chatwoot installation data

Backups are crucial for any software system, including Chatwoot, for several reasons:
Disaster Recovery: Backups serve as your safety net in the event of catastrophic incidents like hardware failure, data center outage, or natural disasters. They allow you to restore your application to its previous state quickly.
Data Loss Prevention: Accidental data deletion or alteration due to human errors, software bugs, or malicious attacks can lead to significant losses. Backups provide a way to recover such lost or corrupted data.
Audit and Compliance: Certain regulations require businesses to maintain backups for a specific period. These backups may serve as reference points for audits or compliance checks.
Business Continuity: In situations where your primary data source becomes unavailable, having a backup allows your business to continue its operations with minimal disruption.
In short, backups are an essential part of risk management and ensure the smooth operation of your software system.
​
What Data Should Be Backed Up?
Postgres Database
Storage (File uploads/Other Assets in Your Installation)
Configuration Variables
Code Customisations
​
Postgres Database
If you are managing the Postgres service yourself, you can use the pg_dump tool provided by PostgreSQL for this purpose.
pg_dump -U postgres -W -F t chatwoot_production > backup.tar
If you are using a managed provider like AWS, Google Cloud, or Azure, enable backups using the options provided by your provider.
​
Storage
Based on your storage configuration, you should take the appropriate steps.
If you are using a managed provider like S3, GCS, etc., ensure backups using the options available with the provider. If you are using the local storage provider, ensure to take a disk backup of the storage folder in the root of your Chatwoot Installation.
​
Configuration
Important configuration might be stored in environment variables. You should back these up as well. Make a copy of the .env file or keep a backup of these configurations based on your setup.
​
Code Customisations
Official Chatwoot updates using tools like cwctl assume that there are no customisations done to the Chatwoot installation. We don’t provide support for custom modifications of the Chatwoot codebase. If you are planning any such modifications, please ensure that you back up these customisations using git or other appropriate tooling.
​
Guidelines
The frequency of backups largely depends on the nature of your application and the amount of data you generate and can afford to lose. You can opt for continuous or daily backups as per your need.
Remember, these backups should be stored in a different physical location to protect against hardware failures. Using a cloud storage provider could be a good solution. Please ensure that access to these backups is tightly controlled, as they contain sensitive data.
​
Restoring a Backup
To restore a backup into a new Chatwoot installation, please follow these steps:
Set up a new Chatwoot installation and finish the onboarding flow.
Ensure that the configuration values match the ones in your backup.
Purge the database of this installation and replace it with the data from your postgres backup.
Restore Storage with your backup data.
Restore any Code Customisations.
Restart Chatwoot services and you are good to go.
Instagram App Review
Complete guide for submitting Instagram App Review request to get advanced messaging permissions for Chatwoot integration

This document provides a customizable template for brands requesting advanced Instagram permissions. Use this template to submit an Instagram App Review request and demonstrate how your app uses advanced messaging permissions to provide real-time customer support through Instagram.
​
Requested Permissions
instagram_business_basic – Retrieve connected Instagram Business account metadata (username, ID, profile picture).
instagram_business_manage_messages – Receive and respond to direct messages.
human_agent – Enable human responses beyond the standard 24-hour window.
Please replace all placeholder values such as BRAND_NAME, DASHBOARD_URL, EMAIL, and PASSWORD before submitting.
​
Start the Review Process
​
Add the Website Platform
Navigate to the basic settings and add the Website platform. Provide your frontend URL in the platform configuration.
Add platform
​
Go to the App Review Section
Go to the Instagram product and click on “Go to App Review”.
Go to App Review
​
Confirm the Documentation
Click on “Continue” to confirm the documentation.
Confirm documentation
​
Select the Permissions
Select the permissions instagram_business_basic, instagram_business_manage_messages, and human_agent and click on “Continue to App Review”.
Select permissions
​
Configure App Review Requests
After clicking on “Continue to App Review”, you will be redirected to the App Review requests page.
App Review requests
Click on the “Edit” button to edit the review request.
Edit review request
​
Business Account
You must have a Business Account to be able to request these permissions. Please ensure you have a Business Account before requesting the permissions. Submit Business Account details.
Business Account details
​
Data Handling
Please answer all the questions in the Data Handling section and include all the pre-processing steps you perform on the data.
Data handling questionsData handling
​
Complete App Settings
Make sure you have an app icon, privacy policy URL, and app category configured. You can update these via the Basic Settings.
App settings
​
Review Instructions
Provide the review instructions to the reviewer for the App Review. Essentially, you need to provide the steps to log in to the Dashboard and send a message to the connected Instagram account.
Review instructions
You can use the following template to provide the review instructions:
Go to [DASHBOARD_URL].
Log in using the following credentials. Ensure the credentials are entered exactly as provided, without leading or trailing spaces.
Email: [EMAIL]
Password: [PASSWORD]
Once logged in, you will see the Dashboard with an empty chat screen. On the leftmost sidebar, you will find the Settings (gear icon).
Click on Settings > Inboxes > Add Inbox. You can also access the settings page at: [DASHBOARD_URL]/app/accounts/[ACCOUNT_ID]/settings/inboxes/new.
On the first step, “Choose a channel,” select Instagram. This will take you to the second step, where you will find the “Continue with Instagram” button.
Once the setup is complete, you can send a message to the connected Instagram account.
The message should appear on the Dashboard at [DASHBOARD_URL]/app/accounts/[ACCOUNT_ID]/dashboard.
Review instructions details
​
Permissions
It is time to request the permissions. Please click on each permission and fill in the details. Once you are done, click on “Submit for Review”. Below are sample permission requests you can use as a reference.
Permission requests
​
instagram_business_basic
​
Why You Are Requesting This Permission
[BRAND_NAME] is a customer support platform that allows businesses to manage conversations across multiple messaging platforms — including Instagram, WhatsApp, Facebook, and more — through a unified inbox.
This permission is used to:
Retrieve basic metadata (username, user ID, and profile picture) of connected Instagram Business accounts during onboarding.
Display sender information (username and ID) when customers message the business through Instagram.
This metadata is essential for correct routing of messages to the appropriate agent, identification of the agent handling the conversation, and accurate profile display in the chat UI, ensuring a seamless customer experience.
App URL: [DASHBOARD_URL]
Test Account:
Email: [EMAIL]
Password: [PASSWORD]
​
Screencast Walkthrough
Include a screencast demonstrating the following steps:
Log in to the app using the provided credentials.
Navigate to the Dashboard.
Add a new inbox by selecting Instagram as the channel.
Authenticate an Instagram Business account.
Show that the platform uses the instagram_business_basic permission to display:
Instagram username
User ID
Profile picture
Simulate receiving a message and show how this metadata appears in the inbox.
​
instagram_business_manage_messages
​
Why You Are Requesting This Permission
[BRAND_NAME] is a customer support platform that allows businesses to manage conversations across multiple messaging platforms — including Instagram, WhatsApp, Facebook, and more — through a unified inbox.
This permission allows the platform to manage and respond to Instagram messages on behalf of the connected Instagram Business account.
It is used to:
Receive messages via the Instagram webhook.
Display conversations in the agent inbox.
Allow agents to reply from within the platform.
Keep conversations synced in real time.
The webhook setup works by configuring a URL endpoint on the platform to receive incoming messages from Instagram. When a message is sent to the connected Instagram Business account, it triggers a webhook event that delivers the message to the specified endpoint. The backend processes this message, stores it in the database, and updates the agent’s inbox in real time.
Without this permission, users would not be able to communicate with their Instagram audience via the support platform.
App URL: [DASHBOARD_URL]
Test Account:
Email: [EMAIL]
Password: [PASSWORD]
​
Screencast Walkthrough
Include a screencast demonstrating the following steps:
Log in to the Dashboard.
Connect an Instagram Business account as described in the previous section.
From another Instagram user account, send a direct message to the connected business.
Show that the message appears in the inbox UI.
Reply from the inbox.
Switch back to Instagram to show that the user received the reply.
Demonstrate real-time syncing.
​
human_agent
​
Why You Are Requesting This Permission
[BRAND_NAME] is a customer support platform that allows businesses to manage conversations across multiple messaging platforms — including Instagram, WhatsApp, Facebook, and more — through a unified inbox.
We are requesting the Human Agent permission to allow support agents to follow up on customer conversations beyond the 24-hour window, especially when customers reach out after business hours or over the weekend.
Example use case:
A customer sends a message Friday night.
The business is closed on weekends.
On Monday morning, the agent cannot reply because the 24-hour window has expired.
With the Human Agent tag, the agent can now follow up on Monday morning and resolve the query.
This enhances customer experience and ensures critical messages are not left unresolved due to timing limitations.
This permission is essential to allow human agents to continue conversations in a natural, respectful, and supportive way without forcing customers to message again just to reopen the window.
App URL: [DASHBOARD_URL]
Test Account:
Email: [EMAIL]
Password: [PASSWORD]
​
Screencast Walkthrough
Include a screencast demonstrating the following steps:
Log in to the platform.
Open an existing Instagram conversation that is older than 24 hours.
Attempt to respond to the message and explain how current Meta policy restricts the reply.
Explain why a response is still needed — for example, the support agent was unavailable during a weekend or the issue required escalation.
Describe how the human_agent tag will be used to allow the response within the extended 7-day window.
​
Notes
Do not include Instagram account credentials.
Only share test Dashboard credentials (non-super admin access recommended).
Ensure your screencast clearly shows the platform UI and relevant workflows.
Keep your permission usage aligned with Meta’s policy for message tags and user privacy.
Speak aloud or add captions in your video for reviewer clarity.
Video should be as detailed as possible.
Managing Enterprise Edition Features
Learn how to manage and configure Chatwoot Enterprise Edition features including licensing, pricing, and advanced capabilities

Chatwoot Enterprise Edition is a proprietary version of Chatwoot software designed for larger organizations that require advanced features such as Whitelabeling, SLA Management, Audit Logs, Agent Capacity Managment, etc. It is developed from the same GitHub repository as the Community Edition but includes additional, proprietary features aimed at supporting commercial business needs.
The Enterprise Edition offers direct support options and an easy upgrade path to paid features, ensuring that businesses can scale their operations efficiently without needing to reinstall the software. For more detailed information, you can visit the Chatwoot Enterprise Edition User Guide.
​
Managing Enterprise Edition Plan
To activate the Enterprise Plan, head over to the Settings tab in your Super Admin panel. It displays your current plan; clicking on the manage button will let you access the portal where you can purchase the appropriate number of licenses.
Our pricing plans start at $19 per agent per month. For more detailed information, please refer to the self-hosted pricing plans.
​
Settings Overview
Manage Enterprise Plan
Installation Identifier: This is the unique identifier used to identify an installation and associate a license with that installation.
Manage Plan: Redirects to the Stripe portal where you can purchase the appropriate number of licenses.
Refresh: Refresh button next to plan details helps to sync your server with the license server in cases where a license purchase is not yet reflected in the system.
Feature Config: You can configure settings for enterprise features like Whitelabeling by clicking on the gear icon next to the feature name under feature settings.
Support Options: Based on your plan, applicable support options will be displayed.
​
FAQ
​
Do you have Instance level plans?
No, at the moment Chatwoot only offers per agent per month plans. If you are looking at a large number of agents, you can reach out to us at sales@one-link.kz for custom plans.
​
Transferring licenses?
If you are moving the installation between servers and doing so with a database backup, the original installation identifier is retained, and you don’t need to activate the license again.
If for some reason you decide to delete an existing licensed installation and want to do a new installation, please reach out to Chatwoot support, and our team can help you transfer the license to your new installation.