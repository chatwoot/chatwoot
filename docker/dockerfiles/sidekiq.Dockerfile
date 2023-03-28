# Use a Ruby base image
FROM ruby:2.7.4-alpine3.14

# Set the working directory inside the container
WORKDIR /app

# Install dependencies
RUN apk add --no-cache build-base \
    && gem install bundler \
    && bundle config set without 'development test' \
    && bundle config --global frozen 1

# Copy your Sidekiq application code into the container
COPY . .

# Expose the default Sidekiq port (if necessary)
EXPOSE 7432

# Define the command to start Sidekiq
CMD ["bundle", "exec", "sidekiq"]