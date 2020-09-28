# pre-build stage
ARG VARIANT=2.7
FROM mcr.microsoft.com/vscode/devcontainers/ruby:${VARIANT}

# Update args in docker-compose.yaml to set the UID/GID of the "vscode" user.
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then \
        groupmod --gid $USER_GID vscode \
        && usermod --uid $USER_UID --gid $USER_GID vscode \
        && chmod -R $USER_UID:$USER_GID /home/vscode; \
    fi

# [Option] Install Node.js
ARG INSTALL_NODE="true"
ARG NODE_VERSION="lts/*"
RUN if [ "${INSTALL_NODE}" = "true" ]; then su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi


# tmux is for overmind 
# TODO : install foreman in future
# packages: postgresql-server-dev-all 
# may be postgres in same machine 

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends \
    libssl-dev \
    tar \
    tzdata \
    postgresql-client \
    yarn \
    git \
    imagemagick \
    tmux \
    zsh

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1


# Do the set up required for chatwoot app 
WORKDIR /workspace
COPY . /workspace

# TODO: figure out installing rvm
# RUN rvm install
COPY Gemfile Gemfile.lock ./
RUN gem install bundler
RUN bundle install
COPY package.json yarn.lock ./
RUN yarn install
