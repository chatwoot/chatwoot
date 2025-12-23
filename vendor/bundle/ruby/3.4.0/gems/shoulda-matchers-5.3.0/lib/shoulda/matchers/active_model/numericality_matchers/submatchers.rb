module Shoulda
  module Matchers
    module ActiveModel
      module NumericalityMatchers
        # @private
        class Submatchers
          def initialize(submatchers)
            @submatchers = submatchers
          end

          def matches?(subject)
            @subject = subject
            failing_submatchers.empty?
          end

          def failure_message
            last_failing_submatcher.failure_message
          end

          def failure_message_when_negated
            last_failing_submatcher.failure_message_when_negated
          end

          def add(submatcher)
            @submatchers << submatcher
          end

          def last_failing_submatcher
            failing_submatchers.last
          end

          private

          def failing_submatchers
            @_failing_submatchers ||= @submatchers.reject do |submatcher|
              submatcher.matches?(@subject)
            end
          end
        end
      end
    end
  end
end
