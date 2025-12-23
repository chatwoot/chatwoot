# frozen_string_literal: true

module JWT
  # Deprecations module to handle deprecation warnings in the gem
  # @api private
  module Deprecations
    class << self
      def context
        yield.tap { emit_warnings }
      ensure
        Thread.current[:jwt_warning_store] = nil
      end

      def warning(message, only_if_valid: false)
        method_name = only_if_valid ? :store : :warn
        case JWT.configuration.deprecation_warnings
        when :once
          return if record_warned(message)
        when :warn
          # noop
        else
          return
        end

        send(method_name, "[DEPRECATION WARNING] #{message}")
      end

      def store(message)
        (Thread.current[:jwt_warning_store] ||= []) << message
      end

      def emit_warnings
        return if Thread.current[:jwt_warning_store].nil?

        Thread.current[:jwt_warning_store].each { |warning| warn(warning) }
      end

      private

      def record_warned(message)
        @warned ||= []
        return true if @warned.include?(message)

        @warned << message
        false
      end
    end
  end
end
