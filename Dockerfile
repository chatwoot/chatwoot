# vim: set ft=dockerfile:
FROM ruby:2.6-slim

ENV AWS_ACCESS_KEY_ID="" \
    AWS_REGION="" \
    AWS_SECRET_ACCESS_KEY="" \
    CHARGEBEE_API_KEY="" \
    CHARGEBEE_SITE="" \
    CHARGEBEE_WEBHOOK_PASSWORD="" \
    CHARGEBEE_WEBHOOK_USERNAME="" \
    DB_HOST="postgres" \
    DB_NAME="chatwoot" \
    DB_PASS="" \
    DB_USER="chatwoot" \
    DEBIAN_FRONTEND="noninteractive" \
    FB_APP_ID="" \
    FB_APP_SECRET="" \
    FB_VERIFY_TOKEN="" \
    FRONTEND_URL="http://localhost:3000" \
    RAILS_ENV="production" \
    RAILS_LOG_TO_STDOUT="true" \
    REDIS_URL="redis://redis:6379" \
    S3_BUCKET_NAME="" \
    SECRET_KEY_BASE="lithahgaef6aSeGhoh8Aelei0Aemoh6geequeec1oerohLichio1bie3eeYah5oh" \
    SENTRY_DSN="" \
    SES_ADDRESS="" \
    SES_PASSWORD="" \
    SES_USERNAME=""

RUN apt-get update \
    && apt-get -qq -y install \
    build-essential \
    curl \
    git \
    imagemagick \
    libpq-dev \
    && curl -L https://deb.nodesource.com/setup_12.x | bash - \
    && curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo 'deb https://dl.yarnpkg.com/debian stable main' > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get -qq -y install nodejs yarn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/chatwoot
WORKDIR /opt/chatwoot
COPY . /opt/chatwoot

RUN bundle
RUN yarn
COPY docker/database.yml /opt/chatwoot/config/database.yml
COPY docker/application.yml /opt/chatwoot/config/application.yml
RUN bundle exec rake assets:precompile

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
