# frozen_string_literal: true

require 'mini_profiler/version'
require 'mini_profiler/asset_version'

require 'mini_profiler'

require 'patches/sql_patches'
require 'patches/net_patches'

if defined?(::Rails) && defined?(::Rails::VERSION) && ::Rails::VERSION::MAJOR.to_i >= 3
  require 'mini_profiler_rails/railtie'
end
