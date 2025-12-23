ARG RUBY_IMAGE
FROM ${RUBY_IMAGE}

ARG USER_ID_GROUP
ARG FRAMEWORKS
ARG VENDOR_PATH
ARG BUNDLER_VERSION

# For tzdata
# ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
      && apt-get install -qq -y --no-install-recommends \
        build-essential libpq-dev git \
      && rm -rf /var/lib/apt/lists/*

# Configure bundler and PATH
ENV LANG=C.UTF-8

ENV GEM_HOME=$VENDOR_PATH
ENV BUNDLE_PATH=$GEM_HOME \
  BUNDLE_JOBS=4 BUNDLE_RETRY=3
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
  BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH=/app/bin:$BUNDLE_BIN:$PATH

ENV FRAMEWORKS $FRAMEWORKS

RUN mkdir -p $VENDOR_PATH \
      && chown -R $USER_ID_GROUP $VENDOR_PATH

USER $USER_ID_GROUP

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
      gem install bundler:$BUNDLER_VERSION

# Use unpatched, system version for more speed over less security
RUN gem install nokogiri -- --use-system-libraries
# Rake is required to build http-parser on some jruby images
RUN gem install rake

WORKDIR /app
