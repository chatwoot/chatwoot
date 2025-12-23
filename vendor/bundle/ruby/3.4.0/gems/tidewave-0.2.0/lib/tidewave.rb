# frozen_string_literal: true

require "tidewave/version"
require "tidewave/railtie"
require "tidewave/database_adapter"

# Ensure DatabaseAdapters module is available
module Tidewave
  module DatabaseAdapters
    # This module is defined here to ensure it's available for autoloading
    # Individual adapters are loaded on-demand in database_adapter.rb
  end
end
