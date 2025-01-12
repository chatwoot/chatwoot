# frozen_string_literal: true

if Rails.env.development? && ENV.fetch('ENABLE_MINI_PROFILER', 'false') == 'true'
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
