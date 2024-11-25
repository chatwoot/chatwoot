release: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare && echo $SOURCE_VERSION > .git_sha
web: bundle exec rails ip_lookup:setup && bin/rails server -p $PORT -e $RAILS_ENV
default_worker: bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq/default.yml
quarantine_worker: bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq/quarantine.yml
