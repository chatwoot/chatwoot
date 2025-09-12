# syntax = docker/dockerfile:1.2

# Usar versão específica do Ruby que coincide com o Gemfile
FROM ruby:3.4.4-slim as base

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

# Install Node.js (usar versão compatível com o projeto)
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn@$YARN_VERSION

WORKDIR /app

# Copy package files
COPY package.json ./
COPY yarn.lock ./

# Install Node dependencies
RUN yarn install --frozen-lockfile

# Copy Gemfile and install Ruby dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install -j4

# Copy application code
COPY . .

# Precompile assets
RUN RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile

# Production image
FROM ruby:3.4.4-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libpq-dev \
    curl \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy from build stage
COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=base /app /app

# Set environment variables
ENV RAILS_ENV=production
ENV NODE_ENV=production

# Expose port
EXPOSE 3000

# Start command
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
