# syntax=docker/dockerfile:1.4

# ------------------------------------------------------------------------------
# Estágio 1: Builder
# ------------------------------------------------------------------------------
FROM ruby:3.4.4 as builder

# versões alinhadas com package.json
ARG NODE_VERSION=23
ARG PNPM_VERSION=10.2.0

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      git \
      curl \
      gnupg2 \
      ca-certificates \
      python3 \
      make \
      g++ \
      libvips \
      imagemagick \
      libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# instala Node 23
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm@${PNPM_VERSION}

# aumenta limite de heap do Node para build
ENV NODE_OPTIONS="--max-old-space-size=6144"

WORKDIR /app

# instala gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 20 --retry 5 --without development test

# instala deps JS
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --reporter verbose

# copia o restante do app
COPY . .

# ==============================================================================
# >>>>> CORREÇÃO ADICIONADA AQUI <<<<<
# Remove o código da versão Enterprise para evitar conflitos de inicialização.
# ==============================================================================
RUN rm -rf enterprise

# precompila assets
RUN RAILS_ENV=production \
    SECRET_KEY_BASE=dummy \
    DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres \
    REDIS_URL=redis://localhost:6379/0 \
    NODE_ENV=production \
    bundle exec rails assets:precompile --trace

# ------------------------------------------------------------------------------
# Estágio 2: Final
# ------------------------------------------------------------------------------
FROM ruby:3.4.4

# Adiciona o repositório do Node.js e o instala
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      curl \
      gnupg2 \
      ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends \
      nodejs \
      libpq-dev \
      postgresql-client \
      libvips \
      imagemagick \
      libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-e", "production", "-b", "0.0.0.0"]
