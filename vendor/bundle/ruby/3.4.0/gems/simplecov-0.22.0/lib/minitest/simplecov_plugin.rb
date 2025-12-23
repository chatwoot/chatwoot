# frozen_string_literal: true

# How minitest plugins. See https://github.com/simplecov-ruby/simplecov/pull/756 for why we need this.
# https://github.com/seattlerb/minitest#writing-extensions
module Minitest
  def self.plugin_simplecov_init(_options)
    if defined?(SimpleCov)
      SimpleCov.external_at_exit = true

      Minitest.after_run do
        SimpleCov.at_exit_behavior
      end
    end
  end
end
