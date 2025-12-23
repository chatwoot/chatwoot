# frozen_string_literal: true

if defined?(Rack::MINI_PROFILER_PREPEND_MYSQL2_PATCH)
  require "patches/db/mysql2/prepend"
else
  require "patches/db/mysql2/alias_method"
end
