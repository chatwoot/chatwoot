# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Or < Binary
        def type
          :or
        end
        alias_method :operator, :type

        def call(input)
          left_result = left.(input)

          if left_result.success?
            Result::SUCCESS
          else
            right_result = right.(input)

            if right_result.success?
              Result::SUCCESS
            else
              Result.new(false, id) { [:or, [left_result.to_ast, right_result.to_ast]] }
            end
          end
        end

        def [](input)
          left[input] || right[input]
        end
      end
    end
  end
end
