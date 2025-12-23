# frozen_string_literal: true

require "dry/schema/constants"

module Dry
  module Schema
    # Represents a list of keys defined by the DSL
    #
    # KeyMap objects expose an API for introspecting schema keys and the ability
    # to rebuild an input hash using configured coercer function.
    #
    # Instances of this class are used as the very first step by the schema processors.
    #
    # @api public
    class KeyMap
      extend ::Dry::Core::Cache

      include ::Dry.Equalizer(:keys)
      include ::Enumerable

      # @return [Array<Key>] A list of defined key objects
      attr_reader :keys

      # Coerce a list of key specs into a key map
      #
      # @example
      #   KeyMap[:id, :name]
      #   KeyMap[:title, :artist, tags: [:name]]
      #   KeyMap[:title, :artist, [:tags]]
      #
      # @return [KeyMap]
      #
      # @api public
      def self.[](*keys)
        new(keys)
      end

      # Build new, or returned a cached instance of a key map
      #
      # @param [Array<Symbol>, Array, Hash<Symbol=>Array>] args
      #
      # @return [KeyMap]
      def self.new(*args)
        fetch_or_store(*args) { super }
      end

      # Set key objects
      #
      # @api private
      def initialize(keys)
        @keys = keys.map { |key|
          case key
          when Hash
            root, rest = key.flatten
            Key::Hash[root, members: KeyMap[*rest]]
          when Array
            root, rest = key
            Key::Array[root, member: KeyMap[*rest]]
          when Key
            key
          else
            Key[key]
          end
        }
      end

      # Write a new hash based on the source hash
      #
      # @param [Hash] source The source hash
      # @param [Hash] target The target hash
      #
      # @return [Hash]
      #
      # @api public
      def write(source, target = EMPTY_HASH.dup)
        each { |key| key.write(source, target) }
        target
      end

      # Return a new key map that is configured to coerce keys using provided coercer function
      #
      # @return [KeyMap]
      #
      # @api public
      def coercible(&coercer)
        self.class.new(map { |key| key.coercible(&coercer) })
      end

      # Return a new key map with stringified keys
      #
      # A stringified key map is suitable for reading hashes with string keys
      #
      # @return [KeyMap]
      #
      # @api public
      def stringified
        self.class.new(map(&:stringified))
      end

      # @api private
      def to_dot_notation
        @to_dot_notation ||= map(&:to_dot_notation).flatten
      end

      # Iterate over keys
      #
      # @api public
      def each(&)
        keys.each(&)
      end

      # Return a new key map merged with the provided one
      #
      # @param [KeyMap, Array] other Either a key map or an array with key specs
      #
      # @return [KeyMap]
      def +(other)
        self.class.new(keys + other.to_a)
      end

      # Return a string representation of a key map
      #
      # @return [String]
      def inspect
        "#<#{self.class}[#{keys.map(&:dump).map(&:inspect).join(", ")}]>"
      end

      # Dump keys to their spec format
      #
      # @return [Array]
      def dump
        keys.map(&:dump)
      end
    end
  end
end
