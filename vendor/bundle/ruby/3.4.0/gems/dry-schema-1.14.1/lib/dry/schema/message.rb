# frozen_string_literal: true

require "dry/initializer"

module Dry
  module Schema
    # Message objects used by message sets
    #
    # @api public
    class Message
      include ::Dry::Equalizer(:text, :path, :predicate, :input)

      extend ::Dry::Initializer

      # @!attribute [r] text
      #   Message text representation created from a localized template
      #   @return [String]
      option :text

      # @!attribute [r] path
      #   Path to the value
      #   @return [String]
      option :path

      # @!attribute [r] predicate
      #   Predicate identifier that was used to produce a message
      #   @return [Symbol]
      option :predicate

      # @!attribute [r] args
      #   Optional list of arguments used by the predicate
      #   @return [Array]
      option :args, default: proc { EMPTY_ARRAY }

      # @!attribute [r] input
      #   The input value
      #   @return [Object]
      option :input

      # @!attribute [r] meta
      #   Arbitrary meta data
      #   @return [Hash]
      option :meta, optional: true, default: proc { EMPTY_HASH }

      # Dump the message to a representation suitable for the message set hash
      #
      # @return [String,Hash]
      #
      # @api public
      def dump
        @dump ||= meta.empty? ? text : {text: text, **meta}
      end
      alias_method :to_s, :dump

      # Dump the message into a hash
      #
      # The hash will be deeply nested if the path's size is greater than 1
      #
      # @see Message#to_h
      #
      # @return [Hash]
      #
      # @api public
      def to_h
        @to_h ||= _path.to_h(dump)
      end

      # See if another message is the same
      #
      # If a string is passed, it will be compared with the text
      #
      # @param other [Message,String]
      #
      # @return [Boolean]
      #
      # @api private
      def eql?(other)
        other.is_a?(::String) ? text == other : super
      end

      # @api private
      def to_or(root)
        clone = dup
        clone.instance_variable_set("@path", path - root.to_a)
        clone.instance_variable_set("@_path", nil)
        clone
      end

      # See which message is higher in the hierarchy
      #
      # @api private
      def <=>(other)
        l_path = _path
        r_path = other._path

        unless l_path.same_root?(r_path)
          raise ::ArgumentError, "Cannot compare messages from different root paths"
        end

        l_path <=> r_path
      end

      # @api private
      def _path
        @_path ||= Path[path]
      end
    end
  end
end
