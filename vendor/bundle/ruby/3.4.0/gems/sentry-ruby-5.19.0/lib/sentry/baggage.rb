# frozen_string_literal: true

require 'cgi'

module Sentry
  # A {https://www.w3.org/TR/baggage W3C Baggage Header} implementation.
  class Baggage
    SENTRY_PREFIX = 'sentry-'
    SENTRY_PREFIX_REGEX = /^sentry-/.freeze

    # @return [Hash]
    attr_reader :items

    # @return [Boolean]
    attr_reader :mutable

    def initialize(items, mutable: true)
      @items = items
      @mutable = mutable
    end

    # Creates a Baggage object from an incoming W3C Baggage header string.
    #
    # Sentry items are identified with the 'sentry-' prefix and stored in a hash.
    # The presence of a Sentry item makes the baggage object immutable.
    #
    # @param header [String] The incoming Baggage header string.
    # @return [Baggage, nil]
    def self.from_incoming_header(header)
      items = {}
      mutable = true

      header.split(',').each do |item|
        item = item.strip
        key, val = item.split('=')

        next unless key && val
        next unless key =~ SENTRY_PREFIX_REGEX

        baggage_key = key.split('-')[1]
        next unless baggage_key

        items[CGI.unescape(baggage_key)] = CGI.unescape(val)
        mutable = false
      end

      new(items, mutable: mutable)
    end

    # Make the Baggage immutable.
    # @return [void]
    def freeze!
      @mutable = false
    end

    # A {https://develop.sentry.dev/sdk/performance/dynamic-sampling-context/#envelope-header Dynamic Sampling Context}
    # hash to be used in the trace envelope header.
    # @return [Hash]
    def dynamic_sampling_context
      @items
    end

    # Serialize the Baggage object back to a string.
    # @return [String]
    def serialize
      items = @items.map { |k, v| "#{SENTRY_PREFIX}#{CGI.escape(k)}=#{CGI.escape(v)}" }
      items.join(',')
    end
  end
end
