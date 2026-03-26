# frozen_string_literal: true

if Rails.env.development? && ENV['DISABLE_MINI_PROFILER'].blank?
  unless defined?(Rack::File)
    Rails.logger.warn('Skipping rack-mini-profiler initialization: Rack::File is unavailable on this Rack version')
    return
  end

  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
