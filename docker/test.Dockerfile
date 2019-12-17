FROM chatwoot:development

ENV RAILS_ENV test
ENV SECRET_KEY_BASE precompile_placeholder

# generate production assets if production environment
RUN bundle exec rake assets:precompile

EXPOSE 3000

# This Dockerfile creates image for chatwoot:test