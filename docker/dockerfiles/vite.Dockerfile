FROM chatwoot:development

RUN apk add --no-cache ruby ruby-dev ruby-bundler \
  nodejs npm curl build-base openssl openssl-dev yaml-dev && \
  npm install -g pnpm@$PNPM_VERSION

RUN gem uninstall bundler --all --executables || true
RUN gem install bundler -v $BUNDLER_VERSION

ENV BUNDLER_VERSION=$BUNDLER_VERSION
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Configure bundle to use the correct gem path
ENV BUNDLE_PATH="/gems"
ENV GEM_HOME="/gems"
ENV GEM_PATH="/gems"

# Install the correct bundler version in the gem path
RUN GEM_HOME="/gems" GEM_PATH="/gems" gem install bundler -v $BUNDLER_VERSION

RUN chmod +x docker/entrypoints/vite.sh

WORKDIR /app

EXPOSE 3036
CMD ["bin/vite", "dev"]
