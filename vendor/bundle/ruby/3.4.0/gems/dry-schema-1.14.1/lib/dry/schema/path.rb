# frozen_string_literal: true

require "dry/schema/constants"

module Dry
  module Schema
    # Path represents a list of keys in a hash
    #
    # @api private
    class Path
      include ::Dry.Equalizer(:keys)
      include ::Comparable
      include ::Enumerable

      # @return [Array<Symbol>]
      attr_reader :keys

      alias_method :root, :first

      # Coerce a spec into a path object
      #
      # @param [Path, Symbol, String, Hash, Array<Symbol>] spec
      #
      # @return [Path]
      #
      # @api private
      def self.call(spec)
        case spec
        when ::Symbol, ::Array
          new([*spec])
        when ::String
          new(spec.split(DOT).map(&:to_sym))
        when ::Hash
          new(keys_from_hash(spec))
        when self
          spec
        else
          raise ::ArgumentError, "+spec+ must be either a Symbol, Array, Hash or a #{name}"
        end
      end

      # @api private
      def self.[](spec)
        call(spec)
      end

      # Extract a list of keys from a hash
      #
      # @api private
      def self.keys_from_hash(hash)
        hash.inject([]) { |a, (k, v)|
          v.is_a?(::Hash) ? a.push(k, *keys_from_hash(v)) : a.push(k, v)
        }
      end

      # @api private
      def initialize(keys)
        @keys = keys
      end

      # @api private
      def to_h(value = EMPTY_ARRAY.dup)
        value = [value] unless value.is_a?(::Array)

        keys.reverse_each.reduce(value) { |result, key| {key => result} }
      end

      # @api private
      def each(&)
        keys.each(&)
      end

      # @api private
      def include?(other)
        keys[0, other.keys.length].eql?(other.keys)
      end

      # @api private
      def <=>(other)
        return keys.length <=> other.keys.length if include?(other) || other.include?(self)

        first_uncommon_index = (self & other).keys.length

        keys[first_uncommon_index] <=> other.keys[first_uncommon_index]
      end

      # @api private
      def &(other)
        self.class.new(
          keys.take_while.with_index { |key, index| other.keys[index].eql?(key) }
        )
      end

      # @api private
      def last
        keys.last
      end

      # @api private
      def same_root?(other)
        root.equal?(other.root)
      end

      EMPTY = new(EMPTY_ARRAY).freeze
    end
  end
end
