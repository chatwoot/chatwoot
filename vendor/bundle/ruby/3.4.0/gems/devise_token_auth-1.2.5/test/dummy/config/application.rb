# frozen_string_literal: true

require File.expand_path('boot', __dir__)

require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'rails/generators'
require 'rack/cors'

Bundler.require(*Rails.groups)

begin
  case DEVISE_TOKEN_AUTH_ORM
  when :active_record
    require 'active_record/railtie'
  when :mongoid
    require 'mongoid'
    require 'mongoid-locker'
  end
rescue LoadError
end

require 'devise_token_auth'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths += ["#{config.root}/app/#{DEVISE_TOKEN_AUTH_ORM}"]

    if DEVISE_TOKEN_AUTH_ORM == :mongoid
      Mongoid.configure do |config|
        config.load! Rails.root.join('./config/mongoid.yml')
      end
    end
  end
end
