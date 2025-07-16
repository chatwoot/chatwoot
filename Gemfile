source 'https://rubygems.org'

ruby '3.2.2'

##-- base gems for rails --##
gem 'rack-cors', require: 'rack/cors'
gem 'rails', '~> 7.0.8.0'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

##-- rails application helper gems --##
gem 'acts-as-taggable-on'
gem 'attr_extras'
gem 'browser'
gem 'hashie'
gem 'jbuilder'
gem 'kaminari'
gem 'responders', '>= 3.1.1'
gem 'rest-client'
gem 'telephone_number'
gem 'time_diff'
gem 'tzinfo-data'
gem 'valid_email2'
# compress javascript config.assets.js_compressor
gem 'uglifier'
##-- used for single column multiple binary flags in notification settings/feature flagging --##
gem 'flag_shih_tzu'
# Random name generator for user names
gem 'haikunator'
# Template parsing safely
gem 'liquid'
# Parse Markdown to HTML
gem 'commonmarker'
# Validate Data against JSON Schema
gem 'json_schemer'
# Rack middleware for blocking & throttling abusive requests
gem 'rack-attack', '>= 6.7.0'
# a utility tool for streaming, flexible and safe downloading of remote files
gem 'down'
# authentication type to fetch and send mail over oauth2.0
gem 'gmail_xoauth'
# Prevent CSV injection
gem 'csv-safe'

##-- for active storage --##
gem 'aws-sdk-s3', require: false
# original gem isn't maintained actively
# we wanted updated version of faraday which is a dependency for slack-ruby-client
gem 'azure-storage-blob', git: 'https://github.com/chatwoot/azure-storage-ruby', branch: 'chatwoot', require: false
gem 'google-cloud-storage', require: false
gem 'image_processing'

##-- gems for database --#
gem 'groupdate'
gem 'pg'
gem 'redis'
gem 'redis-namespace'
# super fast record imports in bulk
gem 'activerecord-import'

##--- gems for server & infra configuration ---##
gem 'dotenv-rails'
gem 'foreman'
gem 'puma'
gem 'webpacker'
# metrics on heroku
gem 'barnes'

##--- gems for authentication & authorization ---##
gem 'devise', '>= 4.9.3'
gem 'devise-secure_password', git: 'https://github.com/chatwoot/devise-secure_password', branch: 'chatwoot'
gem 'devise_token_auth'
# authorization
gem 'jwt'
gem 'pundit'
# super admin
gem 'administrate', '>= 0.19.0'
gem 'administrate-field-active_storage', '>= 1.0.0'
gem 'administrate-field-belongs_to_search'

##--- gems for pubsub service ---##
# https://karolgalanciak.com/blog/2019/11/30/from-activerecord-callbacks-to-publish-slash-subscribe-pattern-and-event-driven-design/
gem 'wisper', '2.0.0'

##--- gems for channels ---##
gem 'facebook-messenger'
gem 'line-bot-api'
gem 'twilio-ruby', '~> 5.66'
# twitty will handle subscription of twitter account events
# gem 'twitty', git: 'https://github.com/chatwoot/twitty'
gem 'twitty', '~> 0.1.5'
# facebook client
gem 'koala'
# slack client
gem 'slack-ruby-client', '~> 2.2.0'
# for dialogflow integrations
gem 'google-cloud-dialogflow-v2'
gem 'grpc'
# Translate integrations
# 'google-cloud-translate' gem depends on faraday 2.0 version
# this dependency breaks the slack-ruby-client gem
gem 'google-cloud-translate-v3'

##-- apm and error monitoring ---#
# loaded only when environment variables are set.
# ref application.rb
gem 'ddtrace', require: false
gem 'elastic-apm', require: false
gem 'newrelic_rpm', require: false
gem 'newrelic-sidekiq-metrics', '>= 1.6.2', require: false
gem 'scout_apm', require: false
gem 'sentry-rails', '>= 5.14.0', require: false
gem 'sentry-ruby', require: false
gem 'sentry-sidekiq', '>= 5.14.0', require: false

##-- background job processing --##
gem 'sidekiq', '>= 7.1.3'
# We want cron jobs
gem 'sidekiq-cron', '>= 1.12.0'

##-- Push notification service --##
gem 'fcm'
gem 'web-push'

##-- geocoding / parse location from ip --##
# http://www.rubygeocoder.com/
gem 'geocoder'
# to parse maxmind db
gem 'maxminddb'

# to create db triggers
gem 'hairtrigger'

gem 'procore-sift'

# parse email
gem 'email_reply_trimmer'

# TODO: we might have to fork this gem since 0.3.1 has hard depency on nokogir 1.10.
# and this gem hasn't been updated for a while.
gem 'html2text', git: 'https://github.com/chatwoot/html2text_ruby', branch: 'chatwoot'

# to calculate working hours
gem 'working_hours'

# full text search for articles
gem 'pg_search'

# Subscriptions, Billing
gem 'stripe'

## - helper gems --##
## to populate db with sample data
gem 'faker'

# Include logrange conditionally in intializer using env variable
gem 'lograge', '~> 0.14.0', require: false

# worked with microsoft refresh token
gem 'omniauth-oauth2'

gem 'audited', '~> 5.4', '>= 5.4.1'

# need for google auth
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection', '~> 1.0'

## Gems for reponse bot
# adds cosine similarity to postgres using vector extension
gem 'neighbor'
gem 'pgvector'
# Convert Website HTML to Markdown
gem 'reverse_markdown'

# Sentiment analysis
gem 'informers'

### Gems required only in specific deployment environments ###
##############################################################

group :production do
  # we dont want request timing out in development while using byebug
  gem 'rack-timeout'
end

group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'letter_opener'
  gem 'scss_lint', require: false
  gem 'web-console', '>= 4.2.1'

  # used in swagger build
  gem 'json_refs'

  # When we want to squash migrations
  gem 'squasher'

  # profiling
  gem 'rack-mini-profiler', '>= 3.2.0', require: false
  gem 'stackprof'
  # Should install the associated chrome extension to view query logs
  gem 'meta_request'
end

group :test do
  # Cypress in rails.
  gem 'cypress-on-rails'
  # fast cleaning of database
  gem 'database_cleaner'
  # mock http calls
  gem 'webmock'
  # test profiling
  gem 'test-prof'
end

group :development, :test do
  gem 'active_record_query_trace'
  ##--- gems for debugging and error reporting ---##
  # static analysis
  gem 'brakeman'
  gem 'bundle-audit', require: false
  gem 'byebug', platform: :mri
  gem 'climate_control'
  gem 'debug', '~> 1.8'
  gem 'factory_bot_rails', '>= 6.4.2'
  gem 'listen'
  gem 'mock_redis'
  gem 'pry-rails'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'seed_dump'
  gem 'shoulda-matchers'
  gem 'simplecov', '0.17.1', require: false
  gem 'spring'
  gem 'spring-watcher-listen'
end
