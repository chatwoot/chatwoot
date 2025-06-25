# pre-build stage
FROM ruby:3.3.3-alpine3.19 AS pre-builder

# ARG default to production settings
# For development docker-compose file overrides ARGS
ARG BUNDLE_WITHOUT="development:test"
ENV BUNDLE_WITHOUT ${BUNDLE_WITHOUT}
ENV BUNDLER_VERSION=2.5.13
RUN gem install bundler -v "$BUNDLER_VERSION"

ARG RAILS_SERVE_STATIC_FILES=true
ENV RAILS_SERVE_STATIC_FILES ${RAILS_SERVE_STATIC_FILES}

ARG RAILS_ENV=production
ENV RAILS_ENV ${RAILS_ENV}

ARG NODE_OPTIONS="--openssl-legacy-provider"
ENV NODE_OPTIONS ${NODE_OPTIONS}

ENV BUNDLE_PATH="/gems"

RUN apk update && apk add --no-cache \
    curl \    
    openssl \
    tar \
    build-base \
    ruby-dev \
    tzdata \
    postgresql-dev \
    postgresql-client \
    nodejs-current \
    yarn \
    npm \
    git \
    vips \
    imagemagick \
  && mkdir -p /var/app \
  && npm install -g pnpm@${PNPM_VERSION} \
  && pnpm --version \
  && gem install bundler

COPY Gemfile Gemfile.lock ./tmp/
WORKDIR /tmp

# natively compile grpc and protobuf to support alpine musl (dialogflow-docker workflow)
# https://github.com/googleapis/google-cloud-ruby/issues/13306
# adding xz as nokogiri was failing to build libxml
# https://github.com/chatwoot/chatwoot/issues/4045
RUN apk update && apk add --no-cache build-base musl ruby-full ruby-dev gcc make musl-dev openssl openssl-dev g++ linux-headers xz vips
RUN bundle config set --local force_ruby_platform true

# Verify connectivity with rubygems
RUN curl -I https://rubygems.org

# Do not install development or test gems in production
RUN if [ "$RAILS_ENV" = "production" ]; then \
 bundle install -j 4 -r 3 --verbose; \
 else bundle install -j 4 -r 3 --verbose; \
  fi

ENV app /app
RUN mkdir $app
WORKDIR $app
ADD . $app

# creating a log directory so that image wont fail when RAILS_LOG_TO_STDOUT is false
# https://github.com/chatwoot/chatwoot/issues/701
RUN mkdir -p $app/log

# generate production assets if production environment
RUN if [ "$RAILS_ENV" = "production" ]; then \
  SECRET_KEY_BASE=precompile_placeholder RAILS_LOG_TO_STDOUT=enabled \
  bundle exec rake assets:precompile --trace \
  && rm -rf spec node_modules tmp/cache; \
  fi

# Generate .git_sha file with current commit hash
RUN git rev-parse HEAD > /app/.git_sha

# Remove unnecessary files
RUN rm -rf /gems/ruby/3.3.0/cache/*.gem \
  && find /gems/ruby/3.3.0/gems/ \( -name "*.c" -o -name "*.o" \) -delete \
  && rm -rf .git \
  && rm .gitignore

# final build stage
FROM ruby:3.3.3-alpine3.19

ARG NODE_VERSION="23.7.0"
ARG PNPM_VERSION="10.2.0"
ENV NODE_VERSION=${NODE_VERSION}
ENV PNPM_VERSION=${PNPM_VERSION}

ARG BUNDLE_WITHOUT="development:test"
ENV BUNDLE_WITHOUT ${BUNDLE_WITHOUT}
ENV BUNDLER_VERSION=2.5.13
RUN gem install bundler -v "$BUNDLER_VERSION"

ARG EXECJS_RUNTIME="Disabled"
ENV EXECJS_RUNTIME ${EXECJS_RUNTIME}

ARG RAILS_SERVE_STATIC_FILES=true
ENV RAILS_SERVE_STATIC_FILES ${RAILS_SERVE_STATIC_FILES}

ARG BUNDLE_FORCE_RUBY_PLATFORM=1
ENV BUNDLE_FORCE_RUBY_PLATFORM ${BUNDLE_FORCE_RUBY_PLATFORM}

ARG RAILS_ENV=production
ENV RAILS_ENV ${RAILS_ENV}
ENV BUNDLE_PATH="/gems"

RUN apk update && apk add --no-cache \
  curl \    
    openssl \
    tar \
    build-base \
    ruby-dev \
    tzdata \
    postgresql-dev \
    postgresql-client \
    nodejs-current \
    yarn \
    npm \
    git \
    vips \
    imagemagick \
  && npm install -g pnpm@${PNPM_VERSION} \
  && pnpm --version \
  && gem install bundler

COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN if [ "$RAILS_ENV" != "production" ]; then \
  apk add --no-cache curl \
  && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
  && npm install -g pnpm@${PNPM_VERSION} \
  && pnpm --version; \
  fi

COPY package.json pnpm-lock.yaml ./
RUN pnpm i

COPY --from=pre-builder /gems/ /gems/
COPY --from=pre-builder /app /app

# Copy .git_sha file from pre-builder stage
COPY --from=pre-builder /app/.git_sha /app/.git_sha

WORKDIR /app

EXPOSE 3000