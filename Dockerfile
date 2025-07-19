# Stage 1: Build app and precompile assets
FROM ruby:3.4.4-slim as builder
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs curl gnupg git

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn pnpm

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle config set deployment 'true' && bundle install --jobs=4

COPY . .

# ✅ Add dummy secret key to allow precompile to succeed
ENV SECRET_KEY_BASE=dummytoken
RUN RAILS_ENV=production bundle exec rake assets:precompile

# Stage 2: Production image
FROM ruby:3.4.4-slim
RUN apt-get update -qq && apt-get install -y libpq-dev nodejs curl git

WORKDIR /app
COPY --from=builder /app /app

RUN npm install -g yarn

ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV RAILS_LOG_TO_STDOUT=true

EXPOSE 3000
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
