# frozen_string_literal: true

if Rails.env.development? && ENV['DISABLE_MINI_PROFILER'].blank?
  require 'rack-mini-profiler'
  
  # Compatibility shim for Rack 3.x
  # In Rack 3, Rack::File was replaced with Rack::Files
  # rack-mini-profiler still expects Rack::File, so we alias it
  unless defined?(Rack::File)
    Rack::File = Rack::Files
  end

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
