# frozen_string_literal: true

module Datadog
  module Core
    # Contains behavior for handling deprecated functions in the codebase.
    module Deprecations
      # Records the occurrence of a deprecated operation in this library.
      #
      # Currently, these operations are logged to `Datadog.logger` at `warn` level.
      #
      # `disallowed_next_major` adds a message informing that the deprecated operation
      # won't be allowed in the next major release.
      #
      # @yieldreturn [String] a String with the lazily evaluated deprecation message.
      # @param [Boolean] disallowed_next_major whether this deprecation will be enforced in the next major release.
      # @param [Object] key A unique key for the deprecation. Only the first message with the same key will be logged.
      def log_deprecation(disallowed_next_major: true, key: nil)
        return unless log_deprecation?(key)

        Datadog.logger.warn do
          message = yield
          message += ' This will be enforced in the next major release.' if disallowed_next_major
          message
        end

        # Track the deprecation being logged.
        deprecation_logged!(key)

        nil
      end

      private

      # Determines whether a deprecation message should be logged.
      #
      # Internal use only.
      def log_deprecation?(key)
        return true if key.nil?

        # Only allow a deprecation to be logged once.
        !logged_deprecations.key?(key)
      end

      def deprecation_logged!(key)
        return if key.nil?

        logged_deprecations[key] += 1
      end

      # Tracks what deprecation warnings have already been logged
      #
      # Internal use only.
      def logged_deprecations
        @logged_deprecations ||= Hash.new(0)
      end
    end
  end
end
