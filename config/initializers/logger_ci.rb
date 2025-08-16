# In CI/precompile-like environments, log to STDOUT instead of a file.
if Rails.env.development?
  require 'active_support/logger'
  if ENV['CI'] || ENV['RAILS_PRECOMPILE']
    logger = ActiveSupport::Logger.new($stdout)
    Rails.logger = logger
    Rails.application.config.logger = logger if defined?(Rails.application)
  else
    begin
      require 'fileutils'
      FileUtils.mkdir_p(Rails.root.join('log'))
      file_logger = ActiveSupport::Logger.new(Rails.root.join('log/development.log'))
      Rails.logger = file_logger
      Rails.application.config.logger = file_logger if defined?(Rails.application)
    rescue StandardError => e
      warn "Logger init fallback to STDOUT due to: #{e.class}: #{e.message}"
      logger = ActiveSupport::Logger.new($stdout)
      Rails.logger = logger
      Rails.application.config.logger = logger if defined?(Rails.application)
    end
  end
end
