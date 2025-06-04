# frozen_string_literal: true

if Rails.env.development? && !ENV['DISABLE_MINI_PROFILER'].present?
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
