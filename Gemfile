# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.6.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6', github: 'rails/rails'
gem 'sass-rails', '~> 5.0'
gem 'puma', '~> 3.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails'
gem 'therubyracer', platforms: :ruby
gem 'jbuilder', '~> 2.5'
gem 'redis'
gem 'devise', git: 'https://github.com/plataformatec/devise'
gem 'pg'
gem 'facebook-messenger', '~> 0.11.1'
gem 'sidekiq'
gem 'koala'
gem 'omniauth-facebook'
gem 'rest-client'
gem 'telegram-bot-ruby'
gem 'devise_token_auth', git: 'https://github.com/lynndylanhurley/devise_token_auth'
gem 'responders'
gem 'kaminari'
gem 'rack-cors', :require => 'rack/cors'
gem 'acts-as-taggable-on', git: 'https://github.com/mbleigh/acts-as-taggable-on'
#gem 'sinatra', github: 'sinatra'
gem 'wisper', '2.0.0'
gem 'nightfury', '~> 1.0', '>= 1.0.1'
gem 'redis-namespace'
gem 'redis-rack-cache'
gem 'figaro'
gem 'pusher'
gem 'pundit'
gem 'carrierwave-aws'
gem 'mini_magick'
gem 'sentry-raven'
gem 'valid_email2'
gem 'hashie'
gem 'chargebee', '~>2'
gem 'poltergeist'
gem 'phantomjs', :require => 'phantomjs/poltergeist'
gem 'time_diff'
gem 'bootsnap'


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'webpacker'

# for starting different server processes
gem 'foreman'

# static analysis
gem 'brakeman'

group :development do
  gem 'web-console'
  gem 'letter_opener'
end

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'listen'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'seed_dump'
  gem 'rubocop', '~> 0.74.0', require: false
  gem 'rspec-rails', '~> 3.8'
end
