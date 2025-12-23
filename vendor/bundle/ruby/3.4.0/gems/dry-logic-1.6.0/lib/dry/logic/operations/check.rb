# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Check < Unary
        attr_reader :evaluator

        def self.new(rule, **options)
          if options[:evaluator]
            super
          else
            keys = options.fetch(:keys)
            evaluator = Evaluator::Set.new(keys)

            super(rule, **options, evaluator: evaluator)
          end
        end

        def initialize(*rules, **options)
          super
          @evaluator = options[:evaluator]
        end

        def type
          :check
        end

        def call(input)
          *head, tail = evaluator[input]
          result = rule.curry(*head).(tail)

          if result.success?
            Result::SUCCESS
          else
            Result.new(false, id) { [type, [options[:keys], result.to_ast]] }
          end
        end

        def [](input)
          rule[*evaluator[input].reverse]
        end

        def ast(input = Undefined)
          [type, [options[:keys], rule.ast(input)]]
        end
      end
    end
  end
end
