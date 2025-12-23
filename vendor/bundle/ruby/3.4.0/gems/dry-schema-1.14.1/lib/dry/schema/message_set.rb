# frozen_string_literal: true

require "dry/core/equalizer"

module Dry
  module Schema
    # A set of messages used to generate errors
    #
    # @see Result#message_set
    #
    # @api public
    class MessageSet
      include ::Enumerable
      include ::Dry::Equalizer(:messages, :options)

      # A list of compiled message objects
      #
      # @return [Array<Message>]
      attr_reader :messages

      # Options hash
      #
      # @return [Hash]
      attr_reader :options

      # @api private
      def self.[](messages, options = EMPTY_HASH)
        new(messages.flatten, options)
      end

      # @api private
      def initialize(messages, options = EMPTY_HASH)
        @messages = messages
        @options = options
      end

      # Iterate over messages
      #
      # @example
      #   result.errors.each do |message|
      #     puts message.text
      #   end
      #
      # @return [Array]
      #
      # @api public
      def each(&)
        return self if empty?
        return to_enum unless block_given?

        messages.each(&)
      end

      # Dump message set to a hash
      #
      # @return [Hash<Symbol=>Array<String>>]
      #
      # @api public
      def to_h
        @to_h ||= messages_map
      end
      alias_method :to_hash, :to_h

      # Get a list of message texts for the given key
      #
      # @param [Symbol] key
      #
      # @return [Array<String>]
      #
      # @api public
      def [](key)
        to_h[key]
      end

      # Get a list of message texts for the given key
      #
      # @param [Symbol] key
      #
      # @return [Array<String>]
      #
      # @raise KeyError
      #
      # @api public
      def fetch(key)
        self[key] || raise(::KeyError, "+#{key}+ message was not found")
      end

      # Check if a message set is empty
      #
      # @return [Boolean]
      #
      # @api public
      def empty?
        @empty ||= messages.empty?
      end

      # @api private
      def freeze
        to_h
        empty?
        super
      end

      private

      # @api private
      def messages_map(messages = self.messages)
        combine_message_hashes(messages.map(&:to_h)).freeze
      end

      # @api private
      def combine_message_hashes(hashes)
        hashes.reduce(EMPTY_HASH.dup) do |a, e|
          a.merge(e) do |_, *values|
            combine_message_values(values)
          end
        end
      end

      # @api private
      def combine_message_values(values)
        hashes, other = partition_message_values(values)
        combined = combine_message_hashes(hashes)
        flattened = other.flatten

        if flattened.empty?
          combined
        elsif combined.empty?
          flattened
        else
          [flattened, combined]
        end
      end

      # @api private
      def partition_message_values(values)
        values
          .map { |value| value.is_a?(::Array) ? value : [value] }
          .reduce(EMPTY_ARRAY.dup, :+)
          .partition { |value| value.is_a?(::Hash) && !value[:text].is_a?(::String) }
      end
    end
  end
end
