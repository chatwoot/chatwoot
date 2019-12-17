FROM chatwoot:development

ENV RAILS_ENV production
ENV SECRET_KEY_BASE precompile_placeholder

# Do not install development or test gems in production
RUN bundle install -j 4 -r 3 --without development test

# generate production assets
RUN bundle exec rake assets:precompile

EXPOSE 3000

# This Dockerfile creates image for chatwoot:latest