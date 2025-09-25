Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end
  config.public_file_server.enabled = true

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV.fetch('ACTIVE_STORAGE_SERVICE', 'local').to_sym

  config.active_job.queue_adapter = :sidekiq

  # Use environment variable, or check for active dev server URL, or fallback to localhost
  custom_host = ENV['FRONTEND_URL'] || detect_active_public_url || 'localhost:10750'
  Rails.application.routes.default_url_options = { host: custom_host, protocol: 'https' }
  
  # Configure Active Storage to use the correct host for URL generation
  config.active_storage.variant_processor = :mini_magick
  
  # Set Active Storage URL options explicitly
  config.after_initialize do
    Rails.application.routes.default_url_options[:host] = custom_host
    Rails.application.routes.default_url_options[:protocol] = 'https'
    Rails.logger.info "[Config] After initialize - setting URL host to: #{custom_host}" if Rails.logger
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Disable host check during development and allow Tailscale domain
  config.hosts = nil
  config.hosts << "liquid-m3-pro.tail367da4.ts.net" if config.hosts
  config.force_ssl = false
  
  # GitHub Codespaces configuration
  if ENV['CODESPACES']
    # Allow web console access from any IP
    config.web_console.allowed_ips = %w(0.0.0.0/0 ::/0)
    # Allow CSRF from codespace URLs
    config.force_ssl = false
    config.action_controller.forgery_protection_origin_check = false
  end

  # customize using the environment variables
  config.log_level = ENV.fetch('LOG_LEVEL', 'debug').to_sym

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  config.logger = ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 1, ENV.fetch('LOG_SIZE', '1024').to_i.megabytes)

  # Bullet configuration to fix the N+1 queries
  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end
end

# Helper method to detect the active public URL by checking what the dev server is using
def detect_active_public_url
  begin
    # Check if Tailscale URL is saved (from dev-server.sh)
    tailscale_url_file = Rails.root.join('tmp', 'pids', 'tailscale_url.txt')
    if File.exist?(tailscale_url_file)
      tailscale_url = File.read(tailscale_url_file).strip
      Rails.logger.info "[Config] Using saved Tailscale URL: #{tailscale_url}" if Rails.logger && tailscale_url.present?
      return tailscale_url if tailscale_url.present?
    end

    # Check if ngrok is running by trying to fetch tunnel info
    require 'net/http'
    uri = URI('http://localhost:4040/api/tunnels')
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      require 'json'
      tunnels = JSON.parse(response.body)
      public_url = tunnels.dig('tunnels', 0, 'public_url')
      if public_url&.include?('https')
        ngrok_host = public_url.sub(/^https?:\/\//, '')
        Rails.logger.info "[Config] Detected ngrok URL: #{ngrok_host}" if Rails.logger
        return ngrok_host
      end
    end
  rescue => e
    Rails.logger.debug "[Config] Could not detect active public URL: #{e.message}" if Rails.logger
  end

  # Check if custom domain mode is being used (nginx running on port 443)
  begin
    require 'socket'
    TCPSocket.new('localhost', 443).close
    Rails.logger.info "[Config] Using custom domain: dev.rhaps.net" if Rails.logger
    return 'dev.rhaps.net'  # Custom domain is available
  rescue Errno::ECONNREFUSED
    # Custom domain not available
  end

  Rails.logger.info "[Config] No public URL detected, using localhost" if Rails.logger
  nil
end
