# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Negation < Unary
        def type
          :not
        end

        def call(input)
          Result.new(rule.(input).failure?, id) { ast(input) }
        end

        def [](input)
          !rule[input]
        end
      end
    end
  end
end
