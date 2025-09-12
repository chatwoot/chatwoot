# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

## Load the specific APM agent
# We rely on DOTENV to load the environment variables
# We need these environment variables to load the specific APM agent
Dotenv::Rails.load
require 'datadog' if ENV.fetch('DD_TRACE_AGENT_URL', false).present?
require 'elastic-apm' if ENV.fetch('ELASTIC_APM_SECRET_TOKEN', false).present?
require 'scout_apm' if ENV.fetch('SCOUT_KEY', false).present?

if ENV.fetch('NEW_RELIC_LICENSE_KEY', false).present?
  require 'newrelic-sidekiq-metrics'
  require 'newrelic_rpm'
end

if ENV.fetch('SENTRY_DSN', false).present?
  require 'sentry-ruby'
  require 'sentry-rails'
  require 'sentry-sidekiq'
end

# heroku autoscaling
if ENV.fetch('JUDOSCALE_URL', false).present?
  require 'judoscale-rails'
  require 'judoscale-sidekiq'
end

module Chatwoot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('enterprise/lib')
    config.eager_load_paths << Rails.root.join('enterprise/listeners')
    # rubocop:disable Rails/FilePath
    config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
    # rubocop:enable Rails/FilePath
    # Add enterprise views to the view paths
    config.paths['app/views'].unshift('enterprise/app/views')

    # Load enterprise initializers alongside standard initializers
    enterprise_initializers = Rails.root.join('enterprise/config/initializers')
    Dir[enterprise_initializers.join('**/*.rb')].each { |f| require f } if enterprise_initializers.exist?

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.generators.javascripts = false
    config.generators.stylesheets = false

    # Custom chatwoot configurations
    config.x = config_for(:app).with_indifferent_access

    # https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif
    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    # FIX ME : fixes breakage of installation config. we need to migrate.
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]

    # Disable PDF/video preview generation as we don't use them
    config.active_storage.previewers = []

    # Active Record Encryption configuration
    # These keys are required for encrypting sensitive data in the database (e.g., MFA/2FA)
    # In production, always set these via environment variables
    # For CI/CD and initial setup, we provide insecure defaults that should NEVER be used with real data
    config.active_record.encryption.primary_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY', 'insecure_default_primary_key_32b')
    config.active_record.encryption.deterministic_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY', 'insecure_default_deterministic32')
    config.active_record.encryption.key_derivation_salt = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT',
                                                                    'insecure_default_key_salt_value32')
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

  def self.encryption_configured?
    # Check if proper encryption keys are configured
    # MFA/2FA features should only be enabled when proper keys are set
    ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'].present? &&
      ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY'].present? &&
      ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT'].present?
  end

  def self.mfa_enabled?
    encryption_configured?
  end
end
