# frozen_string_literal: true

require "concurrent/map"

module Dry
  module Logic
    def self.Rule(*args, **options, &block)
      if args.any?
        Rule.build(*args, **options)
      elsif block
        Rule.build(block, **options)
      end
    end

    class Rule
      include Core::Constants
      include ::Dry::Equalizer(:predicate, :options)
      include Operators

      attr_reader :predicate

      attr_reader :options

      attr_reader :args

      attr_reader :arity

      def self.interfaces
        @interfaces ||= ::Concurrent::Map.new
      end

      def self.specialize(arity, curried, base = Rule)
        base.interfaces.fetch_or_store([arity, curried]) do
          interface = Interface.new(arity, curried)
          klass = ::Class.new(base) { include interface }
          base.const_set("#{base.name.split("::").last}#{interface.name}", klass)
          klass
        end
      end

      def self.build(predicate, args: EMPTY_ARRAY, arity: predicate.arity, **options)
        specialize(arity, args.size).new(predicate, {args: args, arity: arity, **options})
      end

      def initialize(predicate, options = EMPTY_HASH)
        @predicate = predicate
        @options = options
        @args = options[:args] || EMPTY_ARRAY
        @arity = options[:arity] || predicate.arity
      end

      def type
        :rule
      end

      def id
        options[:id]
      end

      def curry(*new_args)
        with(args: args + new_args)
      end

      def bind(object)
        if predicate.respond_to?(:bind)
          self.class.build(predicate.bind(object), **options)
        else
          self.class.build(
            -> *args { object.instance_exec(*args, &predicate) },
            **options, arity: arity, parameters: parameters
          )
        end
      end

      def eval_args(object)
        with(args: args.map { |arg| arg.is_a?(UnboundMethod) ? arg.bind(object).() : arg })
      end

      def with(new_opts)
        self.class.build(predicate, **options, **new_opts)
      end

      def parameters
        options[:parameters] || predicate.parameters
      end

      def ast(input = Undefined)
        [:predicate, [id, args_with_names(input)]]
      end

      private

      def args_with_names(*input)
        parameters.map(&:last).zip(args + input)
      end
    end
  end
end
