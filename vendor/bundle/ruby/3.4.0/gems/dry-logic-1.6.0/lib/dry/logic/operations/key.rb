# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Key < Unary
        attr_reader :evaluator

        attr_reader :path

        def self.new(rules, **options)
          if options[:evaluator]
            super
          else
            name = options.fetch(:name)
            eval = options.fetch(:evaluator, evaluator(name))
            super(rules, **options, evaluator: eval, path: name)
          end
        end

        def self.evaluator(name)
          Evaluator::Key.new(name)
        end

        def initialize(*rules, **options)
          super
          @evaluator = options[:evaluator]
          @path = options[:path]
        end

        def type
          :key
        end

        def call(hash)
          input = evaluator[hash]
          result = rule.(input)

          if result.success?
            Result::SUCCESS
          else
            Result.new(false, path) { [type, [path, result.to_ast]] }
          end
        end

        def [](hash)
          rule[evaluator[hash]]
        end

        def ast(input = Undefined)
          if input.equal?(Undefined) || !input.is_a?(Hash)
            [type, [path, rule.ast]]
          else
            [type, [path, rule.ast(evaluator[input])]]
          end
        end

        def to_s
          "#{type}[#{path}](#{rule})"
        end
      end
    end
  end
end
