# frozen_string_literal: true

begin
  require "datadog_profiling_native_extension.#{RUBY_VERSION}_#{RUBY_PLATFORM}"
rescue LoadError => e
  raise LoadError,
    "Failed to load the profiling loader extension. To fix this, please remove and then reinstall datadog " \
    "(Details: #{e.message})"
end
