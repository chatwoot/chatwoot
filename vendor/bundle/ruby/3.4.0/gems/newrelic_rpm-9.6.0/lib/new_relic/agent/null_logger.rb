# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# A stub object that we can use in place of a real Logger instance when
# the agent is disabled.
module NewRelic
  module Agent
    class NullLogger
      def fatal(*args); end

      def error(*args); end

      def warn(*args); end

      def info(*args); end

      def debug(*args); end

      def method_missing(method, *args, &blk)
        nil
      end
    end
  end
end
