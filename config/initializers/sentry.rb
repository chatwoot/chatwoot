Raven.configure do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environments = %w[staging production]
end

module QueryTrace
  def self.enable!
    ::ActiveRecord::LogSubscriber.send(:include, self)
  end

  def self.append_features(klass)
    super
    klass.class_eval do
      unless method_defined?(:log_info_without_trace)
        alias_method :log_info_without_trace, :sql
        alias_method :sql, :log_info_with_trace
      end
    end
  end

  def log_info_with_trace(event)
    log_info_without_trace(event)
    trace_log = Rails.backtrace_cleaner.clean(caller).first
    logger.debug("   \\_ \e[33mCalled from:\e[0m #{trace_log}") if trace_log && event.payload[:name] != 'SCHEMA'
  end
end

QueryTrace.enable! unless Rails.env.production?
