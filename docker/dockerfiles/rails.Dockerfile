FROM chatwoot/chatwoot:latest

RUN apk add --no-cache \
  build-base \
  postgresql-dev \
  nodejs \
  npm \
  yarn \
  git \
  bash \
  libxml2-dev \
  libxslt-dev \
  tzdata \
  file \
  protobuf-dev \
  linux-headers \
  libtool \
  autoconf \
  libstdc++ \
  python3 \
  yaml-dev

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN npm install -g pnpm@10.2.0

RUN chmod +x docker/entrypoints/rails.sh

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config set path 'vendor/bundle' \
 && bundle install

COPY . .

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
