FROM ruby:2.6.5-slim

RUN apt-get update \
    && apt-get -qq -y install \
    build-essential \
    curl \
    git \
    imagemagick \
    libpq-dev \
    && curl -L https://deb.nodesource.com/setup_12.x | bash - \
    && curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo 'deb https://dl.yarnpkg.com/debian stable main' > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get -qq -y install nodejs yarn \
    && gem install bundler \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app
WORKDIR /app
COPY . /app

RUN bundle
RUN yarn
RUN bundle exec rake assets:precompile

# Add a script to be executed every time the container starts.
COPY ./docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
