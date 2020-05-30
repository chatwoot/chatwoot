---
path: "/docs/deployment/architecture"
title: "Chatwoot Production deployment guide"
---

This guide will help you to deploy Chatwoot to production!

## Architecture

Running chatwoot in production requires the following set of services. 

* Chatwoot web servers
* Chatwoot workers
* PostgreSQL  Database
* Redis Database
* Email service (SMTP servers / sendgrid / mailgun etc)
* Object Storage ( S3, Azure Storage, GCS, etc)



## Updating your chatwoot installation 

A new version of chatwoot is released around the first monday of every month. We also release minor versions when there is a need for Hotfixes or security updates. 

You can stay tunned to our [Roadmap](https://github.com/chatwoot/chatwoot/milestones) and [releases](https://github.com/chatwoot/chatwoot/releases) on github. We recommend you to stay uptodate with our releases to enjoy the lastest features and security updates. 

The deployment process for newer versions involved updating your app servers and workers with the latest code. Most updates would involve database migrations as well which can be executed through the following rails command. 

```
bundle exec rails db:migrate
```

detailed instructions can be found in respective deployment guides.

### Available deployment options

If you want to self host chatwoot, the recommended approach is to use one of the  recommended one click installation options from the below list. 

But if you are fairly comfortable with ruby on rails applications, you can also make use of the other deployment options mentioned below. 

* [Heroku](/docs/deployment/deploy-chatwoot-with-heroku) (recommended)
* [Caprover](/docs/deployment/deploy-chatwoot-with-caprover) (recommended)
* [Docker](/docs/deployment/deploy-chatwoot-with-docker)
* [Linux](/docs/deployment/deploy-chatwoot-in-linux-vm)


