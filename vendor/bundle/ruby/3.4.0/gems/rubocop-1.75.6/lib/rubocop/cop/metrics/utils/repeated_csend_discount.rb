# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      module Utils
        # @api private
        #
        # Identifies repetitions `&.` on the same variable:
        #
        #  my_var&.foo
        #  my_var&.bar # => repeated
        #  my_var = baz # => reset
        #  my_var&.qux # => not repeated
        module RepeatedCsendDiscount
          def reset_repeated_csend
            @repeated_csend = {}
          end

          def discount_for_repeated_csend?(csend_node)
            receiver = csend_node.receiver

            return false unless receiver.lvar_type?

            var_name = receiver.children.first
            seen = @repeated_csend.fetch(var_name) do
              @repeated_csend[var_name] = csend_node
              return false
            end

            !seen.equal?(csend_node)
          end

          def reset_on_lvasgn(node)
            var_name = node.children.first
            @repeated_csend.delete(var_name)
          end
        end
      end
    end
  end
end
