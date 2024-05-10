# The below image is created out of the Dockerfile.base
# It has the dependencies already installed so that codespace will boot up fast
FROM ghcr.io/chatwoot/chatwoot_codespace:latest

# Do the set up required for chatwoot app
WORKDIR /workspace
COPY . /workspace
RUN yarn && gem install bundler && bundle install

# Install the dependencies
# RUN make burn 

# # Run migrations
# RUN make db

# # Seed data
# RUN make db_seed

# # Start the server
# RUN make run