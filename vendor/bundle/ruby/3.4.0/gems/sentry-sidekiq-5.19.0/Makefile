build:
	bundle install
	gem build sentry-sidekiq.gemspec

test:
	WITH_SENTRY_RAILS=1 bundle exec rspec spec/sentry/rails_spec.rb
	bundle exec rspec
