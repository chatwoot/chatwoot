source 'https://rubygems.org'

ruby '2.6.5'

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
gem 'time_diff'
gem 'tzinfo-data'
gem 'valid_email2'
# compress javascript config.assets.js_compressor
gem 'uglifier'

##-- for active storage --##
gem 'mini_magick'

##-- gems for database --#
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

##--- gems for pubsub service ---##
# https://karolgalanciak.com/blog/2019/11/30/from-activerecord-callbacks-to-publish-slash-subscribe-pattern-and-event-driven-design/
gem 'wisper', '2.0.0'

##--- gems for reporting ---##
gem 'nightfury'

##--- gems for billing ---##
gem 'chargebee'

##--- gems for channels ---##
gem 'facebook-messenger'
gem 'telegram-bot-ruby'
gem 'twitter'
# facebook client
gem 'koala'
# Random name generator
gem 'haikunator'

##--- gems for debugging and error reporting ---##
# static analysis
gem 'brakeman'
gem 'sentry-raven'

##-- TODO: move these gems to appropriate groups --##
# remove this gem in favor of active storage -  github #158
gem 'carrierwave-aws'
gem 'sidekiq'

group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'letter_opener'
  gem 'web-console'
end

group :test do
  gem 'action-cable-testing'
  gem 'mock_redis'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'bundle-audit', require: false
  gem 'byebug', platform: :mri
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'listen'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 4.0.0.beta2'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'seed_dump'
  gem 'spring'
  gem 'spring-watcher-listen'
end
