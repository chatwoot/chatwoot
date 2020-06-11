---
path: "/docs/deployment/deploy-chatwoot-in-linux-vm"
title: "Linux VM Chatwoot Production deployment guide"
---


## Deploying to Linux VM 

We have prepped a deployment script for ubuntu 18.04 . Run the script or refer the script and make changes accordingly to OS

https://github.com/chatwoot/chatwoot/blob/develop/deployment/setup.sh

### After loging in to your linux vm as the root user perform the following steps for intial set up 

1. create the `chatwoot.sh` file and copy the content from [deployment script](https://github.com/chatwoot/chatwoot/blob/develop/deployment/setup.sh).
2. Execute the script and it will take care of the initial chatwoot setup
3. Chatwoot Installation will now be accessible at `http://{your_ip}:3000`

### Configure ngix and letsencrypt 

1. configure nginx to serve as a frontend proxy by following steps in your shell

```
cd /etc/nginx/sites-enabled
nano yourdomain.com.conf
```
2. Add the required nginx config after replacing the `yourdomain.com` in `server_name`
```
server {
  server_name yourdomain.com;
  # where rails app is running
  set $upstream 127.0.0.1:3000;

  # Here we define the web-root for our SSL proof
  location /.well-known {
        # Note that a request for /.well-known/test.html will
       alias /var/www/ssl-proof/chatwoot/.well-known;
  }
  
  location / {
    proxy_pass_header Authorization;
    proxy_pass http://$upstream;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header  X-Forwarded-Proto $scheme;
    proxy_set_header  X-Forwarded-Ssl on; # Optional
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_http_version 1.1;
    proxy_set_header Connection “”;
    proxy_buffering off;
    client_max_body_size 0;
    proxy_read_timeout 36000s;
    proxy_redirect off;
  }
  listen 80;
}
```
3. Verify and reload your nginx config by running following command in shell
```
nginx -t
systemctl reload nginx
```
4. Run letsencrypt and configure ssl 
```
mkdir -p /var/www/ssl-proof/chatwoot/.well-known
certbot --webroot -w /var/www/ssl-proof/chatwoot/  -d yourdomain.com  -i nginx
```

5. You chatwoot installation should be accessible from the `https://yourdomain.com` now.

### Configure the required environment variables 
For your chatwoot installation to properly function you would need to configure some of the essential environment variables like `FRONTEND_URL`, mailer and storage config etc. refer [environment variables](https://www.chatwoot.com/docs/environment-variables) for the full list. 

1. login as chatwoot and edit the .env file 
```shell
# login as chatwoot user 
sudo -i -u chatwoot
cd chatwoot
nano .env
```
2. refer [environment variables](https://www.chatwoot.com/docs/environment-variables) and update the required variables. save the `.env` file.
3. Restart the Chatwoot server and Enjoy using Chatwoot
```
systemctl restart chatwoot.target
```



## Updating your Chatwoot Installation on a Linux VM

Run the following steps on your vm if you made use of our installation script Or making changes accordingly to your OS

```shell
# login as chatwoot user 
sudo -i -u chatwoot

# navigate to the chatwoot directory
cd chatwoot 

# pull the latest version of master
git pull master

# update dependencies 
bundle 
yarn

# recompile the assets 
rake assets:precompile RAILS_ENV=production

# migrate the database schema
RAILS_ENV=production bundle exec rake db:migrate

#Restart the chatwoot server
systemctl restart chatwoot.target

```
