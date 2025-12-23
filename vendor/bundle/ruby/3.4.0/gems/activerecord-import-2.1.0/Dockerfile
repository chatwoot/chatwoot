# Use the official Ruby 3.2 image as a base image
ARG RUBY_VERSION=3.2
FROM ruby:${RUBY_VERSION}-bullseye

# Set the working directory
WORKDIR /usr/src/app

# Install system packages
RUN apt-get update -qq && \
    apt-get install -y default-mysql-client postgresql postgresql-contrib vim && \
    apt-get clean

# Set environment variables
ENV AR_VERSION=7.0

# Copy all files
COPY . .

# Move sample database.yml and install gems
RUN mv test/database.yml.sample test/database.yml && \
    bundle install

CMD ["irb"]
