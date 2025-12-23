# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Binary < Abstract
        attr_reader :left

        attr_reader :right

        def initialize(left, right, **options)
          super
          @left = left
          @right = right
        end

        def ast(input = Undefined)
          [type, [left.ast(input), right.ast(input)]]
        end

        def to_s
          "#{left} #{operator.to_s.upcase} #{right}"
        end
      end
    end
  end
end
