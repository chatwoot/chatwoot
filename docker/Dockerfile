# --------- Stage 1: Node Base Layer ---------
  FROM node:23-alpine as node

  # --------- Stage 2: Ruby Build Stage ---------
  FROM ruby:3.3.3-alpine3.19 as pre-builder

  # ARGs & ENVs
  ARG NODE_VERSION="23.7.0"
  ARG PNPM_VERSION="10.2.0"
  ARG BUNDLER_VERSION="2.5.11"
  ARG BUNDLE_WITHOUT="development:test"
  ARG RAILS_ENV="production"
  ARG RAILS_SERVE_STATIC_FILES="true"
  ARG POSTMARK_API_TOKEN

  ENV NODE_VERSION=${NODE_VERSION} \
      PNPM_VERSION=${PNPM_VERSION} \
      BUNDLER_VERSION=${BUNDLER_VERSION} \
      BUNDLE_WITHOUT=${BUNDLE_WITHOUT} \
      RAILS_ENV=${RAILS_ENV} \
      RAILS_SERVE_STATIC_FILES=${RAILS_SERVE_STATIC_FILES} \
      POSTMARK_API_TOKEN=${POSTMARK_API_TOKEN} \
      NODE_OPTIONS="--max-old-space-size=8192 --openssl-legacy-provider" \
      GENERATE_SOURCEMAP=false \
      BUNDLE_PATH="/gems" \
      BUNDLE_JOBS=2 \
      BUNDLE_RETRY=2

  # Install build dependencies (including openssl-dev and git)
  RUN apk update && apk add --no-cache \
      build-base \
      git \
      curl \
      tzdata \
      openssl \
      openssl-dev \
      postgresql-dev \
      postgresql-client \
      xz \
      ruby-dev \
      vips \
      linux-headers \
      make \
      g++ \
      libc6-compat \
      python3 \
      libuv \
      ca-certificates

  # Setup App Directory
  WORKDIR /app

  # Install Bundler
  RUN gem install bundler -v "${BUNDLER_VERSION}"

  # Copy Node from Node stage
  COPY --from=node /usr/local/bin/node /usr/local/bin/
  COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
  RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
      && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
      && npm install -g pnpm@${PNPM_VERSION} \
      && npm cache clean --force

  # Add PNPM to PATH
  ENV PNPM_HOME="/root/.local/share/pnpm"
  ENV PATH="$PNPM_HOME:$PATH"

  # Install Gems
  COPY Gemfile Gemfile.lock ./
  RUN bundle config set --local force_ruby_platform true \
      && bundle config set without "${BUNDLE_WITHOUT}" \
      && bundle install

  # Install JS dependencies
  COPY package.json pnpm-lock.yaml ./
  RUN echo "engine-strict=false" > .npmrc \
      && pnpm install --frozen-lockfile \
      && pnpm store prune \
      && pnpm cache clean \
      && rm -rf ~/.pnpm-store .npmrc

  # Copy full source
  COPY . /app

  # Ensure log dir
  RUN mkdir -p /app/log

  ARG SECRET_KEY_BASE
  ENV SECRET_KEY_BASE=$SECRET_KEY_BASE

  # Precompile assets
  RUN if [ "$RAILS_ENV" = "production" ]; then \
      NODE_OPTIONS="--max-old-space-size=8192" \
      bundle exec rake assets:precompile && \
      rm -rf spec node_modules tmp/cache /root/.cache /root/.npm; \
      fi

  # Store git SHA for tracking (using file instead of git command)
  RUN if [ -f /app/.git_sha ]; then echo "Git SHA already exists"; else echo "0000000" > /app/.git_sha; fi

  # Cleanup build tools (keep git for runtime)
  RUN apk del build-base openssl-dev linux-headers make g++ python3 \
      && rm -rf /gems/ruby/3.3.0/cache/*.gem \
      && find /gems/ruby/3.3.0/gems/ \( -name "*.c" -o -name "*.o" \) -delete \
      && rm -rf .gitignore /tmp/* /var/tmp/*

  # --------- Stage 3: Final App Image ---------
  FROM ruby:3.3.3-alpine3.19 as final

  ARG RAILS_ENV="production"
  ARG RAILS_SERVE_STATIC_FILES="true"

  ENV RAILS_ENV=${RAILS_ENV} \
      RAILS_SERVE_STATIC_FILES=${RAILS_SERVE_STATIC_FILES} \
      EXECJS_RUNTIME=Disabled \
      BUNDLE_FORCE_RUBY_PLATFORM=1 \
      BUNDLE_PATH="/gems" \
      NODE_OPTIONS="--max-old-space-size=4096"

  # Runtime dependencies (keep git!)
  RUN apk update && apk add --no-cache \
      openssl \
      tzdata \
      postgresql-client \
      vips \
      libstdc++ \
      git \
      libuv

  # Copy Node runtime only
  COPY --from=node /usr/local/bin/node /usr/local/bin/
  COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
  RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
      && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
      && npm install -g pnpm@10.2.0 && npm cache clean --force

  # Copy application
  COPY --from=pre-builder /gems /gems
  COPY --from=pre-builder /app /app
  COPY --from=pre-builder /app/.git_sha /app/.git_sha

  WORKDIR /app

  EXPOSE 3000
