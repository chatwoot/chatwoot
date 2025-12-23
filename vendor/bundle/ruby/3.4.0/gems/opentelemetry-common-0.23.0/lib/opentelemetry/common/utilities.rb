# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'uri'

module OpenTelemetry
  module Common
    # Utilities contains common helpers.
    module Utilities
      extend self

      UNTRACED_KEY = Context.create_key('untraced')
      private_constant :UNTRACED_KEY

      STRING_PLACEHOLDER = ''.encode(::Encoding::UTF_8).freeze

      # Returns nil if timeout is nil, 0 if timeout has expired,
      # or the remaining (positive) time left in seconds.
      #
      # @param [Numeric] timeout The timeout in seconds. May be nil.
      # @param [Numeric] start_time Start time for timeout returned
      #   by {timeout_timestamp}.
      #
      # @return [Numeric] remaining (positive) time left in seconds.
      #   May be nil.
      def maybe_timeout(timeout, start_time)
        return nil if timeout.nil?

        timeout -= (timeout_timestamp - start_time)
        timeout.positive? ? timeout : 0
      end

      # Returns a timestamp suitable to pass as the start_time
      # argument to {maybe_timeout}. This has no meaning outside
      # of the current process.
      #
      # @return [Numeric]
      def timeout_timestamp
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # Converts the provided timestamp to nanosecond integer
      #
      # @param timestamp [Time] the timestamp to convert, defaults to Time.now
      # @return [Integer]
      def time_in_nanoseconds(timestamp = Time.now)
        (timestamp.to_r * 1_000_000_000).to_i
      end

      # Encodes a string in utf8
      #
      # @param [String] string The string to be utf8 encoded
      # @param [optional boolean] binary This option is for displaying binary data
      # @param [optional String] placeholder The fallback string to be used if encoding fails
      #
      # @return [String]
      def utf8_encode(string, binary: false, placeholder: STRING_PLACEHOLDER)
        string = string.to_s

        if binary
          # This option is useful for "gracefully" displaying binary data that
          # often contains text such as marshalled objects
          string.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        elsif string.encoding == ::Encoding::UTF_8
          string
        else
          string.encode(::Encoding::UTF_8)
        end
      rescue StandardError => e
        OpenTelemetry.logger.debug("Error encoding string in UTF-8: #{e}")

        placeholder
      end

      # Truncates a string if it exceeds the size provided.
      #
      # @param [String] string The string to be truncated
      # @param [Integer] size The max size of the string
      #
      # @return [String]
      def truncate(string, size)
        string.size > size ? "#{string[0...size - 3]}..." : string
      end

      def truncate_attribute_value(value, limit)
        case value
        when Array
          value.map { |x| truncate_attribute_value(x, limit) }
        when String
          truncate(value, limit)
        else
          value
        end
      end

      # Disables tracing within the provided block
      # If no block is provided instead returns an
      # untraced ctx.
      #
      # @param [optional Context] context Accepts an explicit context, defaults to current
      def untraced(context = Context.current)
        context = context.set_value(UNTRACED_KEY, true)
        if block_given?
          Context.with_current(context) { |ctx| yield ctx }
        else
          context
        end
      end

      # Detects whether the current context has been set to disable tracing.
      def untraced?(context = nil)
        context ||= Context.current
        !!context.value(UNTRACED_KEY)
      end

      # Returns a URL string with userinfo removed.
      #
      # @param [String] url The URL string to cleanse.
      #
      # @return [String] the cleansed URL.
      def cleanse_url(url)
        cleansed_url = URI.parse(url)
        cleansed_url.password = nil
        cleansed_url.user = nil
        cleansed_url.to_s
      rescue URI::Error
        url
      end

      # Returns the first non nil environment variable requested,
      # or the default value if provided.
      #
      # @param [String] env_vars The environment variable(s) to retrieve
      # @param default The fallback value to return if the requested
      #  env var(s) are not present
      #
      # @return [String]
      def config_opt(*env_vars, default: nil)
        ENV.values_at(*env_vars).compact.fetch(0, default)
      end

      # Returns a true if the provided url is valid
      #
      # @param [String] url the URL string to test validity
      #
      # @return [boolean]
      def valid_url?(url)
        return false if url.nil? || url.strip.empty?

        URI(url)
        true
      rescue URI::InvalidURIError
        false
      end

      # Returns true if exporter is a valid exporter.
      def valid_exporter?(exporter)
        exporter && %i[export shutdown force_flush].all? { |m| exporter.respond_to?(m) }
      end
    end
  end
end

require_relative './http/client_context'
