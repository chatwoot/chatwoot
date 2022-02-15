release: bundle exec rails db:chatwoot_prepare RAILS_ENV=production
web: bin/rails server -p 3002 -e production
worker: bundle exec sidekiq -C config/sidekiq.yml
