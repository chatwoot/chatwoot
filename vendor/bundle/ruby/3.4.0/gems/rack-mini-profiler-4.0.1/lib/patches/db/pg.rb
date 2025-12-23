# frozen_string_literal: true

if defined?(Rack::MINI_PROFILER_PREPEND_PG_PATCH)
  require "patches/db/pg/prepend"
else
  require "patches/db/pg/alias_method"
end
