FROM ruby:2.4

RUN mkdir /twilio
WORKDIR /twilio

COPY Rakefile Gemfile LICENSE README.md twilio-ruby.gemspec ./
COPY lib ./lib

RUN bundle install
RUN bundle exec rake install
