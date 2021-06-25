# The below image is created out of the Dockerfile.base
# It has the dependencies already installed so that codespace will boot up fast
FROM ghcr.io/sojan-official/chatwoot_codespace:latest

# Do the set up required for chatwoot app 
WORKDIR /workspace
COPY . /workspace
RUN yarn

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install