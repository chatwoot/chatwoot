# frozen_string_literal: true

require_relative 'utils/forking'

module Datadog
  module Core
    # Utils contains low-level utilities, typically to provide pseudo-random trace IDs.
    # @public_api
    module Utils
      extend Forking

      EMPTY_STRING = ''.encode(::Encoding::UTF_8).freeze

      # Stringifies `value` and ensures the outcome is
      # string is no longer than `size`.
      # `omission` replaces the end of the output if
      # `value.to_s` does not fit in `size`, to signify
      # truncation.
      #
      # If `omission.size` is larger than `size`, the output
      # will still be `omission.size` in length.
      # @!visibility private
      def self.truncate(value, size, omission = '...')
        string = value.to_s

        return string if string.size <= size

        string = string.slice(0, size - 1)

        if size < omission.size
          string[0, size] = omission
        else
          string[size - omission.size, size] = omission
        end

        string
      end

      # Ensure `str` is a valid UTF-8, ready to be
      # sent through the tracer transport.
      #
      # @param [String,#to_s] str object to be converted to a UTF-8 string
      # @param [Boolean] binary whether to expect binary data in the `str` parameter
      # @param [String] placeholder string to be returned when encoding fails
      # @return a UTF-8 string version of `str`
      # @!visibility private
      def self.utf8_encode(str, binary: false, placeholder: EMPTY_STRING)
        str = str.to_s

        if binary
          # This option is useful for "gracefully" displaying binary data that
          # often contains text such as marshalled objects
          str.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        elsif str.encoding == ::Encoding::UTF_8
          str
        elsif str.empty?
          # DEV Optimization as `nil.to_s` is a very common source for an empty string,
          # DEV but it comes encoded as US_ASCII.
          EMPTY_STRING
        else
          str.encode(::Encoding::UTF_8)
        end
      rescue => e
        Datadog.logger.debug("Error encoding string in UTF-8: #{e}")

        placeholder
      end

      def self.encode_tags(hash)
        # Make sure everything is an utf-8 string, to avoid encoding issues in downstream
        hash.each_with_object({}) do |(key, value), h|
          h[utf8_encode(key)] = utf8_encode(value)
        end
      end

      # @!visibility private
      def self.without_warnings
        # This is typically used when monkey patching functions such as
        # initialize, which Ruby advices you not to. Use cautiously.
        v = $VERBOSE
        $VERBOSE = nil
        begin
          yield
        ensure
          $VERBOSE = v
        end
      end

      # Extracts hostname and port from
      # a string that contains both, separated by ':'.
      # @return [String,Integer] hostname and port
      # @return [nil] if format did not match
      def self.extract_host_port(host_port)
        match = /^([^:]+):(\d+)$/.match(host_port)
        return unless match

        [match[1], match[2].to_i]
      end
    end
  end
end
