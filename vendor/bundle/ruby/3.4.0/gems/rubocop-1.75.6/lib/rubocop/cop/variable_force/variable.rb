# frozen_string_literal: true

module RuboCop
  module Cop
    class VariableForce
      # A Variable represents existence of a local variable.
      # This holds a variable declaration node and some states of the variable.
      class Variable
        VARIABLE_DECLARATION_TYPES = (VARIABLE_ASSIGNMENT_TYPES + ARGUMENT_DECLARATION_TYPES).freeze

        attr_reader :name, :declaration_node, :scope, :assignments, :references, :captured_by_block

        alias captured_by_block? captured_by_block

        def initialize(name, declaration_node, scope)
          unless VARIABLE_DECLARATION_TYPES.include?(declaration_node.type)
            raise ArgumentError,
                  "Node type must be any of #{VARIABLE_DECLARATION_TYPES}, " \
                  "passed #{declaration_node.type}"
          end

          @name = name.to_sym
          @declaration_node = declaration_node
          @scope = scope

          @assignments = []
          @references = []
          @captured_by_block = false
        end

        def assign(node)
          assignment = Assignment.new(node, self)

          mark_last_as_reassigned!(assignment)

          @assignments << assignment
        end

        def mark_last_as_reassigned!(assignment)
          return if captured_by_block?
          return unless assignment.branch == @assignments.last&.branch

          @assignments.last&.reassigned!
        end

        def referenced?
          !@references.empty?
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def reference!(node)
          reference = Reference.new(node, @scope)
          @references << reference
          consumed_branches = nil

          @assignments.reverse_each do |assignment|
            next if consumed_branches&.include?(assignment.branch)

            assignment.reference!(node) unless assignment.run_exclusively_with?(reference)

            # Modifier if/unless conditions are special. Assignments made in
            # them do not put the assigned variable in scope to the left of the
            # if/unless keyword. A preceding assignment is needed to put the
            # variable in scope. For this reason we skip to the next assignment
            # here.
            next if in_modifier_conditional?(assignment)

            break if !assignment.branch || assignment.branch == reference.branch

            unless assignment.branch.may_run_incompletely?
              (consumed_branches ||= Set.new) << assignment.branch
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def in_modifier_conditional?(assignment)
          parent = assignment.node.parent
          parent = parent.parent if parent&.begin_type?
          return false if parent.nil?

          parent.type?(:if, :while, :until) && parent.modifier_form?
        end

        def capture_with_block!
          @captured_by_block = true
        end

        # This is a convenient way to check whether the variable is used
        # in its entire variable lifetime.
        # For more precise usage check, refer Assignment#used?.
        #
        # Once the variable is captured by a block, we have no idea
        # when, where, and how many times the block would be invoked.
        # This means we cannot track the usage of the variable.
        # So we consider it's used to suppress false positive offenses.
        def used?
          @captured_by_block || referenced?
        end

        def should_be_unused?
          name.to_s.start_with?('_')
        end

        def argument?
          ARGUMENT_DECLARATION_TYPES.include?(@declaration_node.type)
        end

        def method_argument?
          argument? && @scope.node.any_def_type?
        end

        def block_argument?
          argument? && @scope.node.block_type?
        end

        def keyword_argument?
          %i[kwarg kwoptarg].include?(@declaration_node.type)
        end

        def explicit_block_local_variable?
          @declaration_node.shadowarg_type?
        end
      end
    end
  end
end
