# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Chatwoot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('enterprise/lib')
    # rubocop:disable Rails/FilePath
    config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
    # rubocop:enable Rails/FilePath

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.generators.javascripts = false
    config.generators.stylesheets = false

    # Custom chatwoot configurations
    config.x = config_for(:app).with_indifferent_access
  end

  def self.config
    @config ||= Rails.configuration.x
  end

  def self.redis_ssl_verify_mode
    # Introduced this method to fix the issue in heroku where redis connections fail for redis 6
    # ref: https://github.com/chatwoot/chatwoot/issues/2420
    #
    # unless the redis verify mode is explicitly specified as none, we will fall back to the default 'verify peer'
    # ref: https://www.rubydoc.info/stdlib/openssl/OpenSSL/SSL/SSLContext#DEFAULT_PARAMS-constant
    ENV['REDIS_OPENSSL_VERIFY_MODE'] == 'none' ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
  end
end
