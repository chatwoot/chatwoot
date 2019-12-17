FROM ruby:2.6.5-slim

RUN apt-get update \
    && apt-get -qq -y install \
    build-essential \
    curl \
    git \
    imagemagick \
    libpq-dev \
    postgresql-client \
    && curl -L https://deb.nodesource.com/setup_12.x | bash - \
    && curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo 'deb https://dl.yarnpkg.com/debian stable main' > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get -qq -y install nodejs yarn \
    && gem install bundler \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app
WORKDIR /app
COPY . /app

RUN yarn install
RUN bundle install -j 4 -r 3

# This Dockerfile creates image for chatwoot:development