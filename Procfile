web: bundle exec rails ip_lookup:setup && bin/rails server -p 7000 -e production
worker: bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
