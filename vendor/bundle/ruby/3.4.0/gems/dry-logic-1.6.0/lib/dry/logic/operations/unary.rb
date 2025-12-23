# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Unary < Abstract
        attr_reader :rule

        def initialize(*rules, **options)
          super
          @rule = rules.first
        end

        def ast(input = Undefined)
          [type, rule.ast(input)]
        end

        def to_s
          "#{type}(#{rule})"
        end
      end
    end
  end
end
