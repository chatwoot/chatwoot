# frozen_string_literal: true

module RuboCop
  module Cop
    class VariableForce
      # A VariableTable manages the lifetime of all scopes and local variables
      # in a program.
      # This holds scopes as stack structure, provides a way to add local
      # variables to current scope, and find local variables by considering
      # variable visibility of the current scope.
      class VariableTable
        def initialize(hook_receiver = nil)
          @hook_receiver = hook_receiver
        end

        def invoke_hook(hook_name, *args)
          @hook_receiver&.send(hook_name, *args)
        end

        def scope_stack
          @scope_stack ||= []
        end

        def push_scope(scope_node)
          scope = Scope.new(scope_node)
          invoke_hook(:before_entering_scope, scope)
          scope_stack.push(scope)
          invoke_hook(:after_entering_scope, scope)
          scope
        end

        def pop_scope
          scope = current_scope
          invoke_hook(:before_leaving_scope, scope)
          scope_stack.pop
          invoke_hook(:after_leaving_scope, scope)
          scope
        end

        def current_scope
          scope_stack.last
        end

        def current_scope_level
          scope_stack.count
        end

        def declare_variable(name, node)
          variable = Variable.new(name, node, current_scope)
          invoke_hook(:before_declaring_variable, variable)
          current_scope.variables[variable.name] = variable
          invoke_hook(:after_declaring_variable, variable)
          variable
        end

        def assign_to_variable(name, node)
          variable = find_variable(name)

          unless variable
            raise "Assigning to undeclared local variable \"#{name}\" " \
                  "at #{node.source_range}, #{node.inspect}"
          end

          mark_variable_as_captured_by_block_if_so(variable)
          variable.assign(node)
        end

        def reference_variable(name, node)
          variable = find_variable(name)

          # In this code:
          #
          #   foo = 1 unless foo
          #
          #   (if
          #     (lvar :foo) nil
          #     (lvasgn :foo
          #       (int 1)))
          #
          # Parser knows whether the foo is a variable or method invocation.
          # This means that if a :lvar node is shown in AST, the variable is
          # assumed to be already declared, even if we haven't seen any :lvasgn
          # or :arg node before the :lvar node.
          #
          # We don't invoke #declare_variable here otherwise
          # Variable#declaration_node will be :lvar node, that is actually not.
          # So just skip.
          return unless variable

          mark_variable_as_captured_by_block_if_so(variable)
          variable.reference!(node)
        end

        def find_variable(name)
          name = name.to_sym

          scope_stack.reverse_each do |scope|
            variable = scope.variables[name]
            return variable if variable

            # Only block scope allows referencing outer scope variables.
            node = scope.node
            return nil unless node.any_block_type?
          end

          nil
        end

        def variable_exist?(name)
          find_variable(name)
        end

        def accessible_variables
          scope_stack.reverse_each.with_object([]) do |scope, variables|
            variables.concat(scope.variables.values)
            break variables unless scope.node.any_block_type?
          end
        end

        private

        def mark_variable_as_captured_by_block_if_so(variable)
          return unless current_scope.node.any_block_type?
          return if variable.scope == current_scope

          variable.capture_with_block!
        end
      end
    end
  end
end
