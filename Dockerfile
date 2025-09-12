# syntax = docker/dockerfile:1.2

FROM ruby:3.2.3-slim-bullseye as base

ARG NODE_VERSION=18.16.0
ARG YARN_VERSION=1.22.19

# Install dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    gnupg2 \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn@$YARN_VERSION

WORKDIR /app

COPY package.json ./
RUN yarn install --frozen-lockfile

COPY Gemfile Gemfile.lock ./
RUN bundle install -j4

COPY . .

# Precompile assets
RUN RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile

# Production image
FROM ruby:3.2.3-slim-bullseye

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libpq-dev \
    curl \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=base /app /app

ENV RAILS_ENV=production
ENV NODE_ENV=production
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
