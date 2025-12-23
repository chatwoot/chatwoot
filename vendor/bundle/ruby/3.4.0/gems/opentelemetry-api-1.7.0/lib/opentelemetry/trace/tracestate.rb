# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Tracestate is a part of SpanContext, represented by an immutable list of
    # string key/value pairs and formally defined by the W3C Trace Context
    # specification https://www.w3.org/TR/trace-context/
    class Tracestate
      class << self
        private :new

        # Returns a newly created Tracestate parsed from the header provided.
        #
        # @param [String] header Encoding of the tracestate header defined by
        #   the W3C Trace Context specification https://www.w3.org/TR/trace-context/
        # @return [Tracestate] A new Tracestate instance or DEFAULT
        def from_string(header) # rubocop:disable Metrics/CyclomaticComplexity:
          return DEFAULT if header.nil? || header.empty?

          hash = header.split(',').each_with_object({}) do |member, memo|
            member.strip!
            kv = member.split('=')
            k, v = *kv
            next unless kv.length == 2 && VALID_KEY.match?(k) && VALID_VALUE.match?(v)

            memo[k] = v
          end
          return DEFAULT if hash.empty?

          new(hash)
        end

        # Returns a Tracestate created from a Hash.
        #
        # @param [Hash<String, String>] hash Key-value pairs to store in the
        #   Tracestate. Keys and values are validated against the W3C Trace
        #   Context specification, and any invalid members are logged at
        #   DEBUG level and dropped.
        # @return [Tracestate] A new Tracestate instance or DEFAULT
        def from_hash(hash)
          hash = hash.select do |k, v|
            valid = VALID_KEY.match?(k) && VALID_VALUE.match?(v)
            OpenTelemetry.logger.debug("Invalid Tracestate member - #{k} : #{v}") unless valid
            valid
          end
          new(hash)
        end

        # @api private
        # Returns a new Tracestate created from the Hash provided. This
        # skips validation of the keys and values, assuming they are already
        # valid.
        # This method is intended only for the use of instance methods in
        # this class.
        def create(hash)
          new(hash)
        end
      end

      MAX_MEMBER_COUNT = 32 # Defined by https://www.w3.org/TR/trace-context/
      VALID_KEY = Regexp.union(%r(^[a-z][a-z0-9_\-*/]{,255}$), %r(^[a-z0-9][a-z0-9_\-*/]{,240}@[a-z][a-z0-9_\-*/]{,13}$)).freeze
      VALID_VALUE = /^[ -~&&[^,=]]{,255}[!-~&&[^,=]]$/
      private_constant(:MAX_MEMBER_COUNT, :VALID_KEY, :VALID_VALUE)

      # @api private
      # The constructor is private and only for use internally by the class.
      # Users should use the {from_hash} or {from_string} factory methods to
      # obtain a {Tracestate} instance.
      #
      # @param [Hash<String, String>] hash Key-value pairs
      # @return [Tracestate]
      def initialize(hash)
        excess = hash.size - MAX_MEMBER_COUNT
        hash = Hash[hash.drop(excess)] if excess.positive?
        @hash = hash.freeze
      end

      # Returns the value associated with the given key, or nil if the key
      # is not present.
      #
      # @param [String] key The key to lookup.
      # @return [String] The value associated with the key, or nil.
      def value(key)
        @hash[key]
      end

      alias [] value

      # Adds a new key/value pair or updates an existing value for a given key.
      # Keys and values are validated against the W3C Trace Context
      # specification, and any invalid members are logged at DEBUG level and
      # ignored.
      #
      # @param [String] key The key to add or update.
      # @param [String] value The value to add or update.
      # @return [Tracestate] self, if unchanged, or a new Tracestate containing
      #   the new or updated key/value pair.
      def set_value(key, value)
        unless VALID_KEY.match?(key) && VALID_VALUE.match?(value)
          OpenTelemetry.logger.debug("Invalid Tracestate member - #{key} : #{value}")
          return self
        end

        h = Hash[@hash]
        h[key] = value
        self.class.create(h)
      end

      # Deletes the key/value pair associated with the given key.
      #
      # @param [String] key The key to remove.
      # @return [Tracestate] self, if unchanged, or a new Tracestate without
      #   the specified key.
      def delete(key)
        return self unless @hash.key?(key)

        h = Hash[@hash]
        h.delete(key)
        self.class.create(h)
      end

      # Returns this Tracestate encoded according to the W3C Trace Context
      # specification https://www.w3.org/TR/trace-context/
      #
      # @return [String] this Tracestate encoded as a string.
      def to_s
        @hash.inject(+'') do |memo, (k, v)|
          memo << k << '=' << v << ','
        end.chop! || ''
      end

      # Returns this Tracestate as a Hash.
      #
      # @return [Hash] the members of this Tracestate
      def to_h
        @hash.dup
      end

      # Returns true if this Tracestate is empty.
      #
      # @return [Boolean] true if this Tracestate is empty, else false.
      def empty?
        @hash.empty?
      end

      # Returns true if this Tracestate equals other.
      #
      # @param [Tracestate] other The Tracestate for comparison.
      # @return [Boolean] true if this Tracestate == other, else false.
      def ==(other)
        @hash == other.to_h
      end

      DEFAULT = new({})
    end
  end
end
