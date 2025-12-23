# frozen_string_literal: true

module Sequel
  class Database
    alias_method :log_duration_original, :log_duration
    def log_duration(duration, message)
      # `duration` will be in seconds, but we need it in milliseconds for internal consistency.
      ::Rack::MiniProfiler.record_sql(message, duration * 1000)
      log_duration_original(duration, message)
    end
  end
end
