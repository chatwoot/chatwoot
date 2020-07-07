---
path: "/docs/deployment/deploy-chatwoot-with-caprover"
title: "Caprover Chatwoot Production deployment guide"
---

### Caprover Overview

Caprover is an extremely easy to use application server management tool. It is blazing fast and uses Docker under the hood. Chatwoot has been made available as a one-click app in Chatwoot and hence the deployment process is very easy.

### Install Caprover on your VM

Finish your caprover installation by referring to [Getting started guid](https://caprover.com/docs/get-started.html).

### Installing Chatwoot in Caprover

Chatwoot is available in the one-click apps option in caprover, find Chatwoot by searching and clicking on it. Replace the default `version` with the latest `version` of chatwoot. User appropriate values for the Postgres and Redis passwords and click install. It should only take a few minutes.

### Configure the necessary environment variables

Caprover will take care of the installation of Postgres and Redis along with the app and worker servers. We would advise you to replace the database/Redis services with managed/standalone servers once you start scaling.

Also, ensure to set the appropriate environment variables for E-mail, Object Store service etc referring to our [Environment variables guide](./environment-variables)

### Upgrading Chatwoot installation

To update your chatwoot installation to the latest version in caprover, Run the following command in deployment tab for web and worker in the method 5: deploy captain-definition

### web

```json
{
  "schemaVersion": 2,
  "dockerfileLines": [
    "FROM chatwoot/chatwoot:latest",
    "RUN chmod +x docker/entrypoints/rails.sh",
    "ENTRYPOINT [\"docker/entrypoints/rails.sh\"]",
    "CMD bundle exec rake db:setup; bundle exec rake db:migrate; bundle exec rails s -b 0.0.0.0 -p 3000"
  ]
}
```

### worker
```json
{
  "schemaVersion": 2,
  "dockerfileLines": [
    "FROM chatwoot/chatwoot:latest",
    "RUN chmod +x docker/entrypoints/rails.sh",
    "ENTRYPOINT [\"docker/entrypoints/rails.sh\"]",
    "CMD bundle exec sidekiq -C config/sidekiq.yml"
  ]
}
```

### Further references

- https://isotropic.co/how-to-install-chatwoot-to-a-digitalocean-droplet/
