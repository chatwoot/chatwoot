source 'https://rubygems.org'

ruby '2.7.1'

##-- base gems for rails --##
gem 'rack-cors', require: 'rack/cors'
gem 'rails'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

##-- rails helper gems --##
gem 'acts-as-taggable-on'
gem 'attr_extras'
gem 'browser'
gem 'hashie'
gem 'jbuilder'
gem 'kaminari'
gem 'responders'
gem 'rest-client'
gem 'telephone_number'
gem 'time_diff'
gem 'tzinfo-data'
gem 'valid_email2'
# compress javascript config.assets.js_compressor
gem 'uglifier'

##-- for active storage --##
gem 'aws-sdk-s3', require: false
gem 'azure-storage-blob', require: false
gem 'google-cloud-storage', require: false
gem 'mini_magick'

##-- gems for database --#
gem 'groupdate'
gem 'pg'
gem 'redis'
gem 'redis-namespace'
gem 'redis-rack-cache'

##--- gems for server & infra configuration ---##
gem 'dotenv-rails'
gem 'foreman'
gem 'puma'
gem 'webpacker'

##--- gems for authentication & authorization ---##
gem 'devise'
gem 'devise_token_auth'
# authorization
gem 'jwt'
gem 'pundit'
# super admin
gem 'administrate'

##--- gems for pubsub service ---##
# https://karolgalanciak.com/blog/2019/11/30/from-activerecord-callbacks-to-publish-slash-subscribe-pattern-and-event-driven-design/
gem 'wisper', '2.0.0'

##--- gems for channels ---##
gem 'facebook-messenger'
gem 'telegram-bot-ruby'
gem 'twilio-ruby', '~> 5.32.0'
# twitty will handle subscription of twitter account events
# gem 'twitty', git: 'https://github.com/chatwoot/twitty'
gem 'twitty'
# facebook client
gem 'koala'
# slack client
gem 'slack-ruby-client'
# Random name generator
gem 'haikunator'

##--- gems for debugging and error reporting ---##
# static analysis
gem 'brakeman'
gem 'scout_apm'
gem 'sentry-raven'

##-- background job processing --##
gem 'sidekiq'

##-- used for single column multiple binary flags in notification settings/feature flagging --##
gem 'flag_shih_tzu'

##-- Push notification service --##
gem 'fcm'
gem 'webpush'

group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'letter_opener'
  gem 'web-console'

  # used in swagger build
  gem 'json_refs', git: 'https://github.com/tzmfreedom/json_refs', ref: 'e32deb0'
end

group :test do
  # Cypress in rails.
  gem 'cypress-on-rails', '~> 1.0'
  # fast cleaning of database
  gem 'database_cleaner'
end

group :development, :test do
  # locking until https://github.com/codeclimate/test-reporter/issues/418 is resolved
  gem 'action-cable-testing'
  gem 'bundle-audit', require: false
  gem 'byebug', platform: :mri
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'listen'
  gem 'mock_redis', git: 'https://github.com/sds/mock_redis', ref: '16d00789f0341a3aac35126c0ffe97a596753ff9'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 4.0.0.beta2'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'scss_lint', require: false
  gem 'seed_dump'
  gem 'shoulda-matchers'
  gem 'simplecov', '0.17.1', require: false
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'webmock'
end
