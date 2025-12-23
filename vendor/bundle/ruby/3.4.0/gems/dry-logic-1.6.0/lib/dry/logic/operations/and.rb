# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class And < Binary
        attr_reader :hints

        def initialize(*, **)
          super
          @hints = options.fetch(:hints, true)
        end

        def type
          :and
        end
        alias_method :operator, :type

        def call(input)
          left_result = left.(input)

          if left_result.success?
            right_result = right.(input)

            if right_result.success?
              Result::SUCCESS
            else
              Result.new(false, id) { right_result.ast(input) }
            end
          else
            Result.new(false, id) do
              left_ast = left_result.to_ast
              hints ? [type, [left_ast, [:hint, right.ast(input)]]] : left_ast
            end
          end
        end

        def [](input)
          left[input] && right[input]
        end
      end
    end
  end
end
