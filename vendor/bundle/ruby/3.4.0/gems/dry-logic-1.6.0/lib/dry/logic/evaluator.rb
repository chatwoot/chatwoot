# frozen_string_literal: true

module Dry
  module Logic
    class Evaluator
      include Dry::Equalizer(:path)

      attr_reader :path

      class Set
        include Dry::Equalizer(:evaluators)

        attr_reader :evaluators

        def self.new(paths)
          super(paths.map { |path| Evaluator::Key.new(path) })
        end

        def initialize(evaluators)
          @evaluators = evaluators
        end

        def call(input)
          evaluators.map { |evaluator| evaluator[input] }
        end
        alias_method :[], :call
      end

      class Key < Evaluator
        def call(input)
          path.reduce(input) { |a, e| a[e] }
        end
        alias_method :[], :call
      end

      class Attr < Evaluator
        def call(input)
          path.reduce(input) { |a, e| a.public_send(e) }
        end
        alias_method :[], :call
      end

      def initialize(path)
        @path = Array(path)
      end
    end
  end
end
