# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Each < Unary
        def type
          :each
        end

        def call(input)
          results = input.map { |element| rule.(element) }
          success = results.all?(&:success?)

          Result.new(success, id) do
            failures = results
              .map
              .with_index { |result, idx| [:key, [idx, result.ast(input[idx])]] if result.failure? }
              .compact

            [:set, failures]
          end
        end

        def [](arr)
          arr.all? { |input| rule[input] }
        end
      end
    end
  end
end
