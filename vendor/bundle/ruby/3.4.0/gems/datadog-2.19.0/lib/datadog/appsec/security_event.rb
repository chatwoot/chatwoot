# frozen_string_literal: true

module Datadog
  module AppSec
    # A class that represents a security event of any kind. It could be an event
    # representing an attack or fingerprinting results as derivatives or an API
    # security check with extracted schema.
    class SecurityEvent
      SCHEMA_KEY_PREFIX = '_dd.appsec.s.'
      FINGERPRINT_KEY_PREFIX = '_dd.appsec.fp.'

      attr_reader :waf_result, :trace, :span

      def initialize(waf_result, trace:, span:)
        @waf_result = waf_result
        @trace = trace
        @span = span
      end

      def attack?
        return @is_attack if defined?(@is_attack)

        @is_attack = @waf_result.is_a?(SecurityEngine::Result::Match)
      end

      def schema?
        return @has_schema if defined?(@has_schema)

        @has_schema = @waf_result.derivatives.any? { |name, _| name.start_with?(SCHEMA_KEY_PREFIX) }
      end

      def fingerprint?
        return @has_fingerprint if defined?(@has_fingerprint)

        @has_fingerprint = @waf_result.derivatives.any? { |name, _| name.start_with?(FINGERPRINT_KEY_PREFIX) }
      end
    end
  end
end
