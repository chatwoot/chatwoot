# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    # A defined setting.
    #
    # @api public
    class Setting
      include Dry::Equalizer(:name, :default, :constructor, :children, :options, inspect: false)

      OPTIONS = %i[default reader constructor mutable cloneable settings config_class].freeze

      DEFAULT_CONSTRUCTOR = -> v { v }.freeze

      MUTABLE_VALUE_TYPES = [Array, Hash, Set, Config].freeze

      # @api public
      attr_reader :name

      # @api public
      attr_reader :default

      # @api public
      attr_reader :mutable

      # @api public
      attr_reader :constructor

      # @api public
      attr_reader :children

      # @api public
      attr_reader :options

      # @api private
      def self.mutable_value?(value)
        MUTABLE_VALUE_TYPES.any? { |type| value.is_a?(type) }
      end

      # @api private
      def initialize(
        name,
        default:,
        constructor: DEFAULT_CONSTRUCTOR,
        children: EMPTY_ARRAY,
        **options
      )
        @name = name
        @default = default
        @mutable = children.any? || options.fetch(:mutable) {
          # Allow `cloneable` as an option alias for `mutable`
          options.fetch(:cloneable) { Setting.mutable_value?(default) }
        }
        @constructor = constructor
        @children = children
        @options = options
      end

      # @api private
      def reader?
        options[:reader].equal?(true)
      end

      # @api public
      def mutable?
        mutable
      end
      alias_method :cloneable?, :mutable?

      # @api private
      def to_value
        if children.any?
          (options[:config_class] || Config).new(children)
        else
          value = default
          value = constructor.(value) unless value.eql?(Undefined)

          mutable? ? value.dup : value
        end
      end
    end
  end
end
