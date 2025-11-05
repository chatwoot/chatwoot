#!/bin/bash
cd /home/deltatec/develop/chatwoot
export RAILS_ENV=${RAILS_ENV:-development}
bundle exec rails ip_lookup:setup
exec bundle exec sidekiq -C config/sidekiq.yml

