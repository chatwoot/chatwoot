FROM openjdk:8-jdk

RUN apt-get update \
    && apt-get install -y libc6-dev --no-install-recommends \
    && apt-get install -y gcc \
    && rm -rf /var/lib/apt/lists/*

ENV JRUBY_VERSION 9.2.14.0

RUN mkdir -p /opt/jruby \
    && curl -fSL https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.tar.gz.sha256 -o /tmp/jruby.sha256 \
    && curl -fSL https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.tar.gz -o /tmp/jruby.tar.gz \
    && echo "$(cat /tmp/jruby.sha256) */tmp/jruby.tar.gz" | sha256sum -c - \
    && tar -zx --strip-components=1 -f /tmp/jruby.tar.gz -C /opt/jruby \
    && update-alternatives --install /usr/local/bin/ruby ruby /opt/jruby/bin/jruby 1

# set the jruby binaries in the path
ENV PATH /opt/jruby/bin:$PATH

# skip installing gem documentation
RUN mkdir -p /opt/jruby/etc \
    && { \
        echo 'install: --no-document'; \
        echo 'update: --no-document'; \
    } >> /opt/jruby/etc/gemrc

# install bundler, gem requires bash to work
# https://github.com/rubygems/rubygems/issues/2534#issuecomment-448843746
RUN gem update --system --conservative || (gem i "rubygems-update:~>2.7" --no-document && update_rubygems) \
    && gem install bundler:2.3.26 rake net-telnet xmlrpc tzinfo-data

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
    && chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

RUN useradd -rm -d /home/jruby -u 1001 jruby
USER jruby
WORKDIR /home/jruby
CMD [ "irb" ]
