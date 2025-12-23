# frozen_string_literal: true

require "dry/core/equalizer"
require "dry/types/options"
require "dry/types/meta"

module Dry
  module Types
    module Composition
      include Type
      include Builder
      include Options
      include Meta
      include Printable
      include ::Dry::Equalizer(
        :left, :right, :options, :meta,
        inspect: false,
        immutable: true
      )

      # @return [Type]
      attr_reader :left

      # @return [Type]
      attr_reader :right

      module Constrained
        def rule
          left.rule.public_send(self.class.operator, right.rule)
        end

        def constrained?
          true
        end
      end

      def self.included(base)
        composition_name = Inflector.demodulize(base)
        ast_type = Inflector.underscore(composition_name).to_sym
        base.define_singleton_method(:ast_type) { ast_type }
        base.define_singleton_method(:composition_name) { composition_name }
        base.const_set("Constrained", ::Class.new(base) { include Constrained })
      end

      # @param [Type] left
      # @param [Type] right
      # @param [Hash] options
      #
      # @api private
      def initialize(left, right, **options)
        super
        @left, @right = left, right
        freeze
      end

      # @return [String]
      #
      # @api public
      def name = "#{left.name} #{self.class.operator} #{right.name}"

      # @return [false]
      #
      # @api public
      def default? = false

      # @return [false]
      #
      # @api public
      def constrained? = false

      # @return [Boolean]
      #
      # @api public
      def optional? = false

      # @param [Object] input
      #
      # @return [Object]
      #
      # @api private
      def call_unsafe(input) = raise ::NotImplementedError

      # @param [Object] input
      #
      # @return [Object]
      #
      # @api private
      def call_safe(input, &) = raise ::NotImplementedError

      # @param [Object] input
      #
      # @api public
      def try(input, &) = raise ::NotImplementedError

      # @api private
      def success(input)
        result = try(input)
        if result.success?
          result
        else
          raise ::ArgumentError, "Invalid success value '#{input}' for #{inspect}"
        end
      end

      # @api private
      def failure(input, _error = nil)
        result = try(input)
        if result.failure?
          result
        else
          raise ::ArgumentError, "Invalid failure value '#{input}' for #{inspect}"
        end
      end

      # @param [Object] value
      #
      # @return [Boolean]
      #
      # @api private
      def primitive?(value) = raise ::NotImplementedError

      # @see Nominal#to_ast
      #
      # @api public
      def to_ast(meta: true)
        [self.class.ast_type,
         [left.to_ast(meta: meta), right.to_ast(meta: meta), meta ? self.meta : EMPTY_HASH]]
      end

      # Wrap the type with a proc
      #
      # @return [Proc]
      #
      # @api public
      def to_proc = proc { |value| self.(value) }
    end
  end
end
