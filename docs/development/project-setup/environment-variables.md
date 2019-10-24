---
path: "/docs/environment-variables"
title: "Environment Variables"
---

### Setup environment variables

Copy `database` and `application` variables to the correct location.

```bash
cp shared/config/database.yml config/database.yml
cp shared/config/application.yml config/application.yml
```

### Configure database

Use the following values in database.yml

```bash
development:
  <<: *default
  username: postgres
  password:
  database: chatwoot_dev
```

Following changes has to be in `config/application.yml`

### Configure FB Channel

To use FB Channel, you have to create an Facebook app in developer portal. You can find more details about creating FB channels [here](https://developers.facebook.com/docs/apps/#register)

```yml
fb_verify_token: ''
fb_app_secret: ''
fb_app_id: ''
```

### Configure emails

For development, you don't need an email provider. Chatwoot uses [letter-opener](https://github.com/ryanb/letter_opener) gem to test emails locally

### Configure frontend URL

Provide the following value as frontend url

```yml
frontend_url: 'http://localhost:3000'
```

### Configure storage

Chatwoot currently supports only S3 bucket as storage. You can read [Creating an S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html) and [Create an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) to configure the following details.

```yml
S3_BUCKET_NAME: ''
AWS_ACCESS_KEY_ID: ''
AWS_SECRET_ACCESS_KEY: ''
AWS_REGION: ''
```

### Configure Redis URL

For development, you can use the following url to connect to redis.

```yml
REDIS_URL: 'redis:://127.0.0.1:6379'
```
