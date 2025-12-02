# frozen_string_literal: true

# Skip rack-mini-profiler when AppSignal gem is loaded to avoid infinite recursion
# in Net::HTTP patches (both gems monkey-patch the same method)
appsignal_loaded = Gem.loaded_specs.key?('appsignal')

if Rails.env.development? && ENV['DISABLE_MINI_PROFILER'].blank? && !appsignal_loaded
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
