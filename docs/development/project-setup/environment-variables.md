---
path: "/docs/environment-variables"
title: "Environment Variables"
---


### Database configuration

You can set Postgres connection URI as `DATABASE_URL` in the environment to connect to the database.

The URI is of the format

```bash
postgresql://[user[:password]@][netloc][:port][,...][/dbname][?param1=value1&...]
```

Alternatively, use the following values in database.yml which lives inside `config` directory.

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

If you would like to use Sendgrid to send your emails, use the following environment variables:
```bash
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_AUTHENTICATION=plain
SMTP_DOMAIN=<your verified domain>
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=<your Sendgrid API key>
```

If you would like to use Mailgun to send your emails, use the following environment variables:
```bash
SMTP_ADDRESS=smtp.mailgun.org
SMTP_AUTHENTICATION=plain
SMTP_DOMAIN=<Your domain, this has to be verified in Mailgun>
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_PORT=587
SMTP_USERNAME=<Your SMTP username, view under Domains tab>
SMTP_PASSWORD=<Your SMTP password, view under Domains tab>
```


If you would like to use Mailchimp to send your emails, use the following environment variables:
Note: Mandrill is the transactional email service for Mailchimp. You need to enable transactional email and login to mandrillapp.com.

```bash
SMTP_ADDRESS=smtp.mandrillapp.com
SMTP_AUTHENTICATION=plain
SMTP_DOMAIN=<Your verified domain in Mailchimp>
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_PORT=587
SMTP_USERNAME=<Your SMTP username displayed under Settings -> SMTP & API info>
SMTP_PASSWORD=<Any valid API key, create an API key under Settings -> SMTP & API Info>
```

### Configure frontend URL

Provide the following value as frontend url

```bash
FRONTEND_URL='http://localhost:3000'
```

### Configure storage

Chatwoot uses [active storage](https://edgeguides.rubyonrails.org/active_storage_overview.html) for storing attachments. The default storage option is the local storage on your server.

But you can change it to use any of the cloud providers like amazon s3, microsoft azure and google gcs etc. Refer [configuring cloud storage](./configuring-cloud-storage) for additional environment variables required.

```bash
ACTIVE_STORAGE_SERVICE='local'
```

### Configure Redis

For development, you can use the following url to connect to redis.

```bash
REDIS_URL='redis:://127.0.0.1:6379'
```

To authenticate redis connections made by app server and sidekiq, if it's protected by a password, use the following
environment variable to set the password.

```bash
REDIS_PASSWORD=
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

### Rails Logging Variables

By default chatwoot will capture `info` level logs in production. Ref [rails docs](https://guides.rubyonrails.org/debugging_rails_applications.html#log-levels) for the additional log level options.
We will also retain 1 GB of your recent logs and your last shifted log file.
You can fine tune these settings using the following environment variables

```bash
# possible values: 'debug', 'info', 'warn', 'error', 'fatal' and 'unknown'
LOG_LEVEL=
# value in megabytes
LOG_SIZE= 1024
```

### Push Notification

Chatwoot uses web push for push notification on the dashboard. Inorder to get the push notifications working you have to setup the following [VAPID](https://tools.ietf.org/html/draft-thomson-webpush-vapid-02) keys.

```bash
VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY=
```

If you are comfortable with the Rails console, you could run `rails console` and run the following commands

```rb
vapid_key = Webpush.generate_key

# Copy the following to environment variables
vapid_key.public_key
vapid_key.private_key
```

Or you can generate a VAPID key from https://d3v.one/vapid-key-generator/

### Using CDN for asset delivery

With the release v1.8.0, we are enabling CDN support for Chatwoot. If you have a high traffic website, we recommend to setup CDN for your asset delivery. Read setting up [CloudFront as your CDN](/docs/deployment/cdn/cloudfront) guide.
