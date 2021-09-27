# pre-build stage
FROM ruby:3.0.2-alpine AS pre-builder

# ARG default to production settings
# For development docker-compose file overrides ARGS
ARG BUNDLE_WITHOUT="development:test"
ENV BUNDLE_WITHOUT ${BUNDLE_WITHOUT}
ENV BUNDLER_VERSION=2.1.2

ARG RAILS_SERVE_STATIC_FILES=true
ENV RAILS_SERVE_STATIC_FILES ${RAILS_SERVE_STATIC_FILES}

ARG RAILS_ENV=production
ENV RAILS_ENV ${RAILS_ENV}

ENV BUNDLE_PATH="/gems"

RUN apk update \
  && apk add \
    openssl \
    tar \
    build-base \
    tzdata \
    postgresql-dev \
    postgresql-client \
    nodejs \
    yarn \
    git \
  && mkdir -p /var/app \
  && gem install bundler

WORKDIR /app

COPY Gemfile Gemfile.lock ./

# natively compile grpc and protobuf to support alpine musl (dialogflow-docker workflow)
# https://github.com/googleapis/google-cloud-ruby/issues/13306
RUN apk add --no-cache musl ruby-full ruby-dev gcc make musl-dev openssl openssl-dev g++ linux-headers
RUN bundle config set --local force_ruby_platform true

# Do not install development or test gems in production
RUN if [ "$RAILS_ENV" = "production" ]; then \
  bundle config set without 'development test'; bundle install -j 4 -r 3; \
  else bundle install -j 4 -r 3; \
  fi

COPY package.json yarn.lock ./
RUN yarn install

COPY . /app

# creating a log directory so that image wont fail when RAILS_LOG_TO_STDOUT is false
# https://github.com/chatwoot/chatwoot/issues/701
RUN mkdir -p /app/log

# generate production assets if production environment
RUN if [ "$RAILS_ENV" = "production" ]; then \
  SECRET_KEY_BASE=precompile_placeholder RAILS_LOG_TO_STDOUT=enabled bundle exec rake assets:precompile \
  && rm -rf spec node_modules tmp/cache; \
  fi

# Remove unnecessary files
RUN rm -rf /gems/ruby/3.0.0/cache/*.gem \
  && find /gems/ruby/3.0.0/gems/ \( -name "*.c" -o -name "*.o" \) -delete

# final build stage
FROM ruby:3.0.2-alpine

ARG BUNDLE_WITHOUT="development:test"
ENV BUNDLE_WITHOUT ${BUNDLE_WITHOUT}
ENV BUNDLER_VERSION=2.1.2

ARG EXECJS_RUNTIME="Disabled"
ENV EXECJS_RUNTIME ${EXECJS_RUNTIME}

ARG RAILS_SERVE_STATIC_FILES=true
ENV RAILS_SERVE_STATIC_FILES ${RAILS_SERVE_STATIC_FILES}

ARG BUNDLE_FORCE_RUBY_PLATFORM=1
ENV BUNDLE_FORCE_RUBY_PLATFORM ${BUNDLE_FORCE_RUBY_PLATFORM}

ARG RAILS_ENV=production
ENV RAILS_ENV ${RAILS_ENV}
ENV BUNDLE_PATH="/gems"

RUN apk add --update --no-cache \
    openssl \
    tzdata \
    postgresql-client \
    imagemagick \
    git \
  && gem install bundler

RUN if [ "$RAILS_ENV" != "production" ]; then \
  apk add nodejs yarn; \
  fi

COPY --from=pre-builder /gems/ /gems/
COPY --from=pre-builder /app /app

WORKDIR /app

EXPOSE 3000
