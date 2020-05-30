---
path: "/docs/deployment/deploy-chatwoot-with-caprover"
title: "Caprover Chatwoot Production deployment guide"
---

## Caprover Overview

Caprover is an extremly easy to use application server managment tool. Its blazing fast and uses docker under the hood. 
Chatwoot has been made available as a one click app in chatwoot and hence the deployment process is very easy. 


## Install caprover on your VM

Finish your caprover installation by refering to [Getting started guid](https://caprover.com/docs/get-started.html). 

## Installing chatwoot in caprover

Chatwoot is available in the one click apps option in caprover, find chatwoot by searching and clicking on it. 
Replace the default `version` with the lastest `version` of chatwoot. User appropriate values for the postgres and redis passwords and click install. It should only take  few minutes. 

## Configure the necessary environment variables 

Caprover will take care of the installation of postgres and redis along with the app and worker servers. We would advice you to replace the database/redis services with managed/standalone onces once you start scaling.  

Also ensure to set the appropriate environment variables for E-mail, Object Store service etc refereing to our [Environment variables guide](./environment-variables)


## Upgrading chatwoot installation

To update your chatwoot installation to the latest version in caprover, Run the following command in deployment tab for for web and worker in the method 5 : deploy captain -definition

### web 
```
{
     "schemaVersion": 2,
     "dockerfileLines": [
                    "FROM chatwoot/chatwoot:latest",
                    "RUN chmod +x docker/entrypoints/rails.sh",
                    "ENTRYPOINT [\"docker/entrypoints/rails.sh\"]",
                     "CMD bundle exec rake db:setup; bundle exec rake db:migrate; bundle exec rails s -b 0.0.0.0 -p 3000" ]
}
```

### worker
```
{
     "schemaVersion": 2,
     "dockerfileLines": [
                    "FROM chatwoot/chatwoot:latest",
                    "RUN chmod +x docker/entrypoints/rails.sh",
                    "ENTRYPOINT [\"docker/entrypoints/rails.sh\"]",
                     "CMD bundle exec sidekiq -C config/sidekiq.yml" ]
}
```



## Further references

- https://isotropic.co/how-to-install-chatwoot-to-a-digitalocean-droplet/