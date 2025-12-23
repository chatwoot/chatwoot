# frozen_string_literal: true

require "simplecov-html"
module SimpleCov
  module Formatter
    class << self
      def from_env(env)
        formatters = [SimpleCov::Formatter::HTMLFormatter]

        # When running under a CI that uses CodeClimate, JSON output is expected
        if env.fetch("CC_TEST_REPORTER_ID", nil)
          require "simplecov_json_formatter"
          formatters.push(SimpleCov::Formatter::JSONFormatter)
        end

        formatters
      end
    end
  end
end
