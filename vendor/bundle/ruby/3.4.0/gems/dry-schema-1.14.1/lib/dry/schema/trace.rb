# frozen_string_literal: true

module Dry
  module Schema
    # Captures predicates defined within the DSL
    #
    # @api private
    class Trace < ::BasicObject
      INVALID_PREDICATES = %i[key?].freeze

      include ::Dry::Equalizer(:compiler, :captures)

      undef eql?

      # @api private
      attr_reader :compiler

      # @api private
      attr_reader :captures

      # @api private
      def initialize(compiler = Compiler.new)
        @compiler = compiler
        @captures = []
      end

      # @api private
      def evaluate(*args, **opts)
        predicates = opts.empty? ? args : args.push(opts)

        evaluate_predicates(predicates).each do |rule|
          append(rule)
        end

        self
      end

      # @api private
      def evaluate_predicates(predicates)
        predicates.flat_map do |predicate|
          if predicate.respond_to?(:call)
            predicate
          elsif predicate.is_a?(::Array)
            predicate.map { |pred| evaluate_predicates(pred).reduce(:&) }.reduce(:|)
          elsif predicate.is_a?(::Hash)
            predicate.map { |pred, *args| __send__(pred, *args) }
          else
            __send__(predicate)
          end
        end
      end

      # @api private
      def append(op)
        captures << op
        self
      end
      alias_method :<<, :append

      # @api private
      def to_rule(name = nil)
        return if captures.empty?

        if name
          compiler.visit([:key, [name, to_ast]])
        else
          reduced_rule
        end
      end

      # @api private
      def to_ast
        reduced_rule.to_ast
      end

      # @api private
      def class
        ::Dry::Schema::Trace
      end

      private

      # @api private
      def reduced_rule
        captures.map(&:to_ast).map(&compiler.method(:visit)).reduce(:and)
      end

      def respond_to_missing?(meth, include_private = false)
        super || (meth.to_s.end_with?(QUESTION_MARK) && compuiler.support?(meth))
      end

      # @api private
      def method_missing(meth, *args, &block)
        if meth.to_s.end_with?(QUESTION_MARK)
          if ::Dry::Schema::Trace::INVALID_PREDICATES.include?(meth)
            ::Kernel.raise InvalidSchemaError, "#{meth} predicate cannot be used in this context"
          end

          unless compiler.support?(meth)
            ::Kernel.raise ::ArgumentError, "#{meth} predicate is not defined"
          end

          predicate = Predicate.new(compiler, meth, args, block)
          predicate.ensure_valid
          predicate
        else
          super
        end
      end
    end
  end
end
