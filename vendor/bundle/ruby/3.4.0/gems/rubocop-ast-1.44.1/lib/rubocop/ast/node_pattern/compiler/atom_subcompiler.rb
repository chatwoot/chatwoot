# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Generates code that evaluates to a value (Ruby object)
        # This value responds to `===`.
        #
        # Doc on how this fits in the compiling process:
        #   /docs/modules/ROOT/pages/node_pattern.adoc
        class AtomSubcompiler < Subcompiler
          private

          def visit_unify
            compiler.bind(node.child) do
              raise Invalid, 'unified variables can not appear first as argument'
            end
          end

          def visit_symbol
            node.child.inspect
          end
          alias visit_number visit_symbol
          alias visit_string visit_symbol
          alias visit_regexp visit_symbol

          def visit_const
            node.child
          end

          def visit_named_parameter
            compiler.named_parameter(node.child)
          end

          def visit_positional_parameter
            compiler.positional_parameter(node.child)
          end

          def visit_set
            set = node.children.to_set(&:child).freeze
            NodePattern::Sets[set]
          end

          # Assumes other types are node patterns.
          def visit_other_type
            compiler.with_temp_variables do |compare|
              code = compiler.compile_as_node_pattern(node, var: compare)
              "->(#{compare}) { #{code} }"
            end
          end
        end
      end
    end
  end
end
