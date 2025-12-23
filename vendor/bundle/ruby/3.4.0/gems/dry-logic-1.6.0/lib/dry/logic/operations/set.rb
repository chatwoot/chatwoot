# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Set < Abstract
        def type
          :set
        end

        def call(input)
          results = rules.map { |rule| rule.(input) }
          success = results.all?(&:success?)

          Result.new(success, id) do
            [type, results.select(&:failure?).map(&:to_ast)]
          end
        end

        def [](input)
          rules.map { |rule| rule[input] }.all?
        end

        def ast(input = Undefined)
          [type, rules.map { |rule| rule.ast(input) }]
        end

        def to_s
          "#{type}(#{rules.map(&:to_s).join(", ")})"
        end
      end
    end
  end
end
