# frozen_string_literal: true

module Sentry
  module Metrics
    class Configuration
      include ArgumentCheckingHelper

      # Enable metrics usage.
      # Starts a new {Sentry::Metrics::Aggregator} instance to aggregate metrics
      # and a thread to aggregate flush every 5 seconds.
      # @return [Boolean]
      attr_accessor :enabled

      # Enable code location reporting.
      # Will be sent once per day.
      # True by default.
      # @return [Boolean]
      attr_accessor :enable_code_locations

      # Optional Proc, called before emitting a metric to the aggregator.
      # Use it to filter keys (return false/nil) or update tags.
      # Make sure to return true at the end.
      #
      # @example
      #   config.metrics.before_emit = lambda do |key, tags|
      #     return nil if key == 'foo'
      #     tags[:bar] = 42
      #     tags.delete(:baz)
      #     true
      #   end
      #
      # @return [Proc, nil]
      attr_reader :before_emit

      def initialize
        @enabled = false
        @enable_code_locations = true
      end

      def before_emit=(value)
        check_callable!("metrics.before_emit", value)

        @before_emit = value
      end
    end
  end
end
