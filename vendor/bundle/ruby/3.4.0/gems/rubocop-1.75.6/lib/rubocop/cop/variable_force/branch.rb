# frozen_string_literal: true

module RuboCop
  module Cop
    class VariableForce
      # Namespace for branch classes for each control structure.
      module Branch
        def self.of(target_node, scope: nil)
          ([target_node] + target_node.ancestors).each do |node|
            return nil unless node.parent
            return nil unless scope.include?(node)

            klass = CLASSES_BY_TYPE[node.parent.type]
            next unless klass

            branch = klass.new(node, scope)
            return branch if branch.branched?
          end

          nil
        end

        # Abstract base class for branch classes.
        # A branch represents a conditional branch in a scope.
        #
        # @example
        #   def some_scope
        #     do_something     # no branch
        #
        #     if foo
        #       do_something   # branch A
        #       do_something   # branch A
        #     else
        #       do_something   # branch B
        #       if bar
        #         do_something # branch C (whose parent is branch B)
        #       end
        #     end
        #
        #     do_something     # no branch
        #   end
        Base = Struct.new(:child_node, :scope) do
          def self.classes
            @classes ||= []
          end

          def self.inherited(subclass)
            super
            classes << subclass
          end

          def self.type
            name.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').downcase.to_sym
          end

          def self.define_predicate(name, child_index: nil)
            define_method(name) do
              target_node = control_node.children[child_index]

              # We don't use Kernel#Array here
              # because it invokes Node#to_a rather than wrapping with an array.
              if target_node.is_a?(Array)
                target_node.any? { |node| node.equal?(child_node) }
              else
                target_node.equal?(child_node)
              end
            end
          end

          def control_node
            child_node.parent
          end

          def parent
            return @parent if instance_variable_defined?(:@parent)

            @parent = Branch.of(control_node, scope: scope)
          end

          def each_ancestor(include_self: false, &block)
            return to_enum(__method__, include_self: include_self) unless block

            yield self if include_self
            scan_ancestors(&block)
            self
          end

          def branched?
            !always_run?
          end

          def always_run?
            raise NotImplementedError
          end

          def may_jump_to_other_branch?
            false
          end

          def may_run_incompletely?
            false
          end

          def exclusive_with?(other)
            return false unless other
            return false if may_jump_to_other_branch?

            other.each_ancestor(include_self: true) do |other_ancestor|
              if control_node.equal?(other_ancestor.control_node)
                return !child_node.equal?(other_ancestor.child_node)
              end
            end

            if parent
              parent.exclusive_with?(other)
            else
              false
            end
          end

          def ==(other)
            return false unless other

            control_node.equal?(other.control_node) && child_node.equal?(other.child_node)
          end

          alias_method :eql?, :==

          def hash
            [control_node.object_id, control_node.object_id].hash
          end

          private

          def scan_ancestors
            branch = self

            while (branch = branch.parent)
              yield branch
            end
          end
        end

        # Mix-in module for simple conditional control structures.
        module SimpleConditional
          def conditional_clause?
            raise NotImplementedError
          end

          def always_run?
            conditional_clause?
          end
        end

        # if conditional_clause
        #   truthy_body
        # else
        #   falsey_body
        # end
        #
        # unless conditional_clause
        #   falsey_body
        # else
        #   truthy_body
        # end
        class If < Base
          include SimpleConditional

          define_predicate :conditional_clause?, child_index: 0
          define_predicate :truthy_body?,        child_index: 1
          define_predicate :falsey_body?,        child_index: 2
        end

        # while conditional_clause
        #   loop_body
        # end
        class While < Base
          include SimpleConditional

          define_predicate :conditional_clause?, child_index: 0
          define_predicate :loop_body?,          child_index: 1
        end

        # until conditional_clause
        #   loop_body
        # end
        class Until < Base
          include SimpleConditional

          define_predicate :conditional_clause?, child_index: 0
          define_predicate :loop_body?,          child_index: 1
        end

        # begin
        #   loop_body
        # end while conditional_clause
        class WhilePost < Base
          include SimpleConditional

          define_predicate :conditional_clause?, child_index: 0
          define_predicate :loop_body?,          child_index: 1
        end

        # begin
        #   loop_body
        # end until conditional_clause
        class UntilPost < Base
          include SimpleConditional

          define_predicate :conditional_clause?, child_index: 0
          define_predicate :loop_body?,          child_index: 1
        end

        # case target
        # when /pattern/ # when_clause
        # else
        #   else_body
        # end
        class Case < Base
          define_predicate :target?,      child_index: 0
          define_predicate :when_clause?, child_index: 1..-2
          define_predicate :else_body?,   child_index: -1

          def always_run?
            target?
          end
        end

        # case target
        # in pattern # in_pattern
        # else
        #   else_body
        # end
        class CaseMatch < Base
          define_predicate :target?,     child_index: 0
          define_predicate :in_pattern?, child_index: 1..-2
          define_predicate :else_body?,  child_index: -1

          def always_run?
            target?
          end
        end

        # for element in collection
        #   loop_body
        # end
        class For < Base
          define_predicate :element?,    child_index: 0
          define_predicate :collection?, child_index: 1
          define_predicate :loop_body?,  child_index: 2

          def always_run?
            element? || collection?
          end
        end

        # Mix-in module for logical operator control structures.
        module LogicalOperator
          def always_run?
            left_body?
          end
        end

        # left_body && right_body
        class And < Base
          include LogicalOperator

          define_predicate :left_body?,  child_index: 0
          define_predicate :right_body?, child_index: 1
        end

        # left_body || right_body
        class Or < Base
          include LogicalOperator

          define_predicate :left_body?,  child_index: 0
          define_predicate :right_body?, child_index: 1
        end

        # Mix-in module for exception handling control structures.
        module ExceptionHandler
          def may_jump_to_other_branch?
            main_body?
          end

          def may_run_incompletely?
            main_body?
          end
        end

        #   begin
        #     main_body
        #   rescue StandardError => error # rescue_clause
        #   else
        #     else_body
        #   end
        class Rescue < Base
          include ExceptionHandler

          define_predicate :main_body?,     child_index: 0
          define_predicate :rescue_clause?, child_index: 1..-2
          define_predicate :else_body?,     child_index: -1

          def always_run?
            false
          end
        end

        #   begin
        #     main_body
        #   ensure
        #     ensure_body
        #   end
        class Ensure < Base
          include ExceptionHandler

          define_predicate :main_body?,   child_index: 0
          define_predicate :ensure_body?, child_index: -1

          def always_run?
            ensure_body?
          end
        end

        CLASSES_BY_TYPE = Base.classes.each_with_object({}) do |klass, classes|
          classes[klass.type] = klass
        end
      end
    end
  end
end
