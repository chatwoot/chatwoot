# Stage 1: Build and precompile assets
FROM ruby:3.4.4-slim as builder

# Install build dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  curl \
  git \
  gnupg \
  nodejs

# Install Node.js and Yarn
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

WORKDIR /app

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && \
    bundle config set deployment 'true' && \
    bundle install --jobs=4

# Copy the full app
COPY . .

# Add dummy secret so asset precompile works
ENV SECRET_KEY_BASE=dummytoken
# RUN RAILS_ENV=production bundle exec rake assets:precompile

# Stage 2: Final production image
FROM ruby:3.4.4-slim

# Install runtime dependencies only
RUN apt-get update -qq && apt-get install -y \
  libpq-dev \
  curl \
  git \
  nodejs

WORKDIR /app

# Copy app from builder (including compiled assets)
COPY --from=builder /app /app

# Skip unnecessary npm/yarn inst