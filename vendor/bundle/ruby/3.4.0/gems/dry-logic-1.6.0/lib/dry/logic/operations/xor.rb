# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Xor < Binary
        def type
          :xor
        end
        alias_method :operator, :type

        def call(input)
          Result.new(self[input], id) { ast(input) }
        end

        def [](input)
          left[input] ^ right[input]
        end

        def ast(input = Undefined)
          [type, rules.map { |rule| rule.ast(input) }]
        end
      end
    end
  end
end
