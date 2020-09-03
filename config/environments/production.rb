Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch('RAILS_SERVE_STATIC_FILES', true))
  # Compress JavaScripts and CSS.
  # config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.action_controller.asset_host = ENV.fetch('ASSET_CDN_HOST') if ENV['ASSET_CDN_HOST'].present?
  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = ENV.fetch('ACTIVE_STORAGE_SERVICE', 'local').to_sym

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  if ENV['FRONTEND_URL'].present?
    config.action_cable.allowed_request_origins = [ENV['FRONTEND_URL'], %r{https?://#{URI.parse(ENV['FRONTEND_URL']).host}(:[0-9]+)?}]
  end

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ActiveModel::Type::Boolean.new.cast(ENV.fetch('FORCE_SSL', false))

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV.fetch('LOG_LEVEL', 'info').to_sym

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  config.active_job.queue_adapter = :sidekiq
  # config.active_job.queue_name_prefix = "Chatwoot_#{Rails.env}"

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  else
    config.logger    = ActiveSupport::Logger.new(
      Rails.root.join('log', Rails.env + '.log'),
      1,
      ENV.fetch('LOG_SIZE', '1024').to_i.megabytes
    )
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Chatwoot production settings
  config.action_mailer.default_url_options = { host: ENV['FRONTEND_URL'] }
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_ADDRESS'],
    port: ENV['SMTP_PORT'] || 587,
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: :login,
    enable_starttls_auto: true
  }

  # Set this to appropriate ingress service for which the options are :
  # :relay for Exim, Postfix, Qmail
  # :mailgun for Mailgun
  # :mandrill for Mandrill
  # :postmark for Postmark
  # :sendgrid for Sendgrid
  config.action_mailbox.ingress = ENV.fetch('RAILS_INBOUND_EMAIL_SERVICE', 'relay').to_sym

  Rails.application.routes.default_url_options = { host: ENV['FRONTEND_URL'] }

  # font cors issue with CDN
  # Ref: https://stackoverflow.com/questions/56960709/rails-font-cors-policy
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '/packs/*', headers: :any, methods: [:get, :options]
    end
  end
end
