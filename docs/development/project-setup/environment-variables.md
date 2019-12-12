---
path: "/docs/environment-variables"
title: "Environment Variables"
---


### Database configuration

Use the following values in database.yml which lives inside `config` directory.

```bash
development:
  <<: *default
  username: postgres
  password:
  database: chatwoot_dev
```

We use `dotenv-rails` gem to manage the environment variables. There is a file called `env.example` in the root directory of this project with all the environment variables set to empty value. You can set the correct values as per the following options. Once you set the values, you should rename the file to `.env` before you start the server.

### Configure FB Channel

To use FB Channel, you have to create an Facebook app in developer portal. You can find more details about creating FB channels [here](https://developers.facebook.com/docs/apps/#register)

```bash
FB_VERIFY_TOKEN=
FB_APP_SECRET=
FB_APP_ID=
```

### Configure emails

For development, you don't need an email provider. Chatwoot uses [letter-opener](https://github.com/ryanb/letter_opener) gem to test emails locally

For production use, use the following variables to set SMTP server.

```bash
MAILER_SENDER_EMAIL=
SMTP_ADDRESS=
SMTP_USERNAME=
SMTP_PASSWORD=
```

### Configure frontend URL

Provide the following value as frontend url

```bash
FRONTEND_URL='http://localhost:3000'
```

### Configure storage

Chatwoot currently supports only S3 bucket as storage. You can read [Creating an S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html) and [Create an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) to configure the following details.

```bash
S3_BUCKET_NAME=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
```

### Configure Redis URL

For development, you can use the following url to connect to redis.

```bash
REDIS_URL='redis:://127.0.0.1:6379'
```

### Configure Postgres host

You can set the following environment variable to set the host for postgres.

```bash
POSTGRES_HOST=localhost
```

For production and testing you have the following variables for defining the postgres database,
username and password.

```bash
POSTGRES_DATABASE=chatwoot_production
POSTGRES_USERNAME=admin
POSTGRES_PASSWORD=password
```

### Rails Production Variables

For production deployment, you have to set the following variables

```bash
RAILS_ENV=production
SECRET_KEY_BASE=replace_with_your_own_secret_string
```

You can generate `SECRET_KEY_BASE` using `rake secret` command from project root folder.

