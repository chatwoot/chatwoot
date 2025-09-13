# syntax = docker/dockerfile:1.2

# Estágio de construção (build stage)
FROM ruby:3.4.4-slim as base

# Define argumentos que podem ser passados durante o build
ARG NODE_VERSION=23
ARG YARN_VERSION=1.22.19
# Argumento para a chave secreta do Rails
ARG SECRET_KEY_BASE

# Instala dependências essenciais do sistema
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    gnupg2 \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instala Node.js e Yarn
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn@$YARN_VERSION

WORKDIR /app

# Copia e instala primeiro as dependências para aproveitar o cache do Docker
COPY package.json ./
RUN yarn install

COPY Gemfile Gemfile.lock ./
RUN bundle install -j4

# Copia o restante do código da aplicação
COPY . .

# Expõe o ARG como uma variável de ambiente para que o comando rake a utilize
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE
# Precompila os assets
RUN RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile

# ---

# Estágio de produção (production image)
FROM ruby:3.4.4-slim

# Instala apenas as dependências necessárias para rodar a aplicação
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libpq-dev \
    curl \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia os arquivos e dependências do estágio de construção
COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=base /app /app

# Expõe a porta 3000
EXPOSE 3000

# Comando para iniciar o servidor Rails
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
