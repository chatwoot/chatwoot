source 'https://rubygems.org'

ruby '2.6.5'

##-- base gems for rails --##
gem 'rack-cors', require: 'rack/cors'
gem 'rails', '~> 6', git: 'https://github.com/rails/rails'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

##-- rails helper gems --##
gem 'acts-as-taggable-on', git: 'https://github.com/mbleigh/acts-as-taggable-on'
gem 'attr_extras'
gem 'browser'
gem 'hashie'
gem 'jbuilder', '~> 2.5'
gem 'kaminari'
gem 'responders'
gem 'time_diff'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'valid_email2'

##-- gems for database --#
gem 'pg'
gem 'redis'
gem 'redis-namespace'
gem 'redis-rack-cache'

##--- gems for server & infra configuration ---##
gem 'dotenv-rails'
gem 'foreman'
gem 'puma', '~> 3.0'
gem 'webpacker'

##--- gems for authentication & authorization ---##
gem 'devise', git: 'https://github.com/plataformatec/devise'
gem 'devise_token_auth', git: 'https://github.com/lynndylanhurley/devise_token_auth'
# authorization
gem 'jwt'
gem 'pundit'

##--- gems for pubsub service ---##
gem 'wisper', '2.0.0'

##--- gems for reporting ---##
gem 'nightfury', '~> 1.0', '>= 1.0.1'

##--- gems for billing ---##
gem 'chargebee', '~>2'

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
gem 'carrierwave-aws'
gem 'mini_magick'
gem 'sidekiq'
gem 'uglifier', '>= 1.3.0'

group :development do
  gem 'letter_opener'
  gem 'web-console'
end

group :test do
  gem 'action-cable-testing'
  gem 'mock_redis'
  gem 'shoulda-matchers'
end

group :development, :test do
  gem 'bundle-audit', require: false
  gem 'byebug', platform: :mri
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'listen'
  gem 'pry-rails'
  gem 'rspec-rails', git: 'https://github.com/rspec/rspec-rails', tag: 'v4.0.0.beta3'
  gem 'rubocop', '~> 0.73.0', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'seed_dump'
  gem 'spring'
  gem 'spring-watcher-listen'
end
