source 'https://rubygems.org'

ruby '2.6.3'

##-- base gems for rails --##
gem 'rails', '~> 6', github: 'rails/rails'
gem 'rack-cors', require: 'rack/cors'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false
gem 'therubyracer', platforms: :ruby


##-- rails helper gems --##
gem 'responders'
gem 'valid_email2'
gem 'attr_extras'
gem 'hashie'
gem 'jbuilder', '~> 2.5'
gem 'kaminari'
gem 'time_diff'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'acts-as-taggable-on', git: 'https://github.com/mbleigh/acts-as-taggable-on'


##-- gems for database --#
gem 'pg'
gem 'redis'
gem 'redis-namespace'
gem 'redis-rack-cache'


##--- gems for server & infra configuration ---##
gem 'puma', '~> 3.0'
gem 'webpacker'
gem 'foreman'
gem 'figaro'


##--- gems for authentication & authorization ---##
gem 'devise', git: 'https://github.com/plataformatec/devise'
gem 'devise_token_auth', git: 'https://github.com/lynndylanhurley/devise_token_auth'
# authorization
gem 'pundit'


##--- gems for pubsub service ---##
gem 'pusher'
gem 'wisper', '2.0.0'


##--- gems for reporting ---##
gem 'nightfury', '~> 1.0', '>= 1.0.1'


##--- gems for billing ---##
gem 'chargebee', '~>2'


##--- gems for channels ---##
gem 'facebook-messenger'
gem 'twitter'
gem 'telegram-bot-ruby'
# facebook client
gem 'koala'


##--- gems for debugging and error reporting ---##
# static analysis
gem 'brakeman'
gem 'sentry-raven'


##-- TODO: move these gems to appropriate groups --##
gem 'carrierwave-aws'
gem 'coffee-rails'
gem 'mini_magick'
gem 'sidekiq'
gem 'uglifier', '>= 1.3.0'


group :development do
  gem 'letter_opener'
  gem 'web-console'
end


group :test do
  gem 'mock_redis'
  gem 'shoulda-matchers'
end

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'listen'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.8'
  gem 'rubocop', '~> 0.73.0', require: false
  gem 'seed_dump'
  gem 'spring'
  gem 'spring-watcher-listen'
end