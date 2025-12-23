# frozen_string_literal: true

module RuboCop
  module Cop
    # This force provides a way to track local variables and scopes of Ruby.
    # Cops interact with this force need to override some of the hook methods.
    #
    #     def before_entering_scope(scope, variable_table)
    #     end
    #
    #     def after_entering_scope(scope, variable_table)
    #     end
    #
    #     def before_leaving_scope(scope, variable_table)
    #     end
    #
    #     def after_leaving_scope(scope, variable_table)
    #     end
    #
    #     def before_declaring_variable(variable, variable_table)
    #     end
    #
    #     def after_declaring_variable(variable, variable_table)
    #     end
    #
    # @api private
    class VariableForce < Force # rubocop:disable Metrics/ClassLength
      VARIABLE_ASSIGNMENT_TYPE = :lvasgn
      REGEXP_NAMED_CAPTURE_TYPE = :match_with_lvasgn
      PATTERN_MATCH_VARIABLE_TYPE = :match_var
      VARIABLE_ASSIGNMENT_TYPES = [
        VARIABLE_ASSIGNMENT_TYPE, REGEXP_NAMED_CAPTURE_TYPE, PATTERN_MATCH_VARIABLE_TYPE
      ].freeze

      ARGUMENT_DECLARATION_TYPES = [
        :arg, :optarg, :restarg,
        :kwarg, :kwoptarg, :kwrestarg,
        :blockarg, # This doesn't mean block argument, it's block-pass (&block).
        :shadowarg # This means block local variable (obj.each { |arg; this| }).
      ].freeze

      LOGICAL_OPERATOR_ASSIGNMENT_TYPES = %i[or_asgn and_asgn].freeze
      OPERATOR_ASSIGNMENT_TYPES = (LOGICAL_OPERATOR_ASSIGNMENT_TYPES + [:op_asgn]).freeze

      MULTIPLE_ASSIGNMENT_TYPE = :masgn
      REST_ASSIGNMENT_TYPE = :splat

      VARIABLE_REFERENCE_TYPE = :lvar

      POST_CONDITION_LOOP_TYPES = %i[while_post until_post].freeze
      LOOP_TYPES = (POST_CONDITION_LOOP_TYPES + %i[while until for]).freeze

      RESCUE_TYPE = :rescue

      ZERO_ARITY_SUPER_TYPE = :zsuper

      TWISTED_SCOPE_TYPES = %i[block numblock itblock class sclass defs module].freeze
      SCOPE_TYPES = (TWISTED_SCOPE_TYPES + [:def]).freeze

      SEND_TYPE = :send

      VariableReference = Struct.new(:name) do
        def assignment?
          false
        end
      end

      AssignmentReference = Struct.new(:node) do
        def assignment?
          true
        end
      end

      def variable_table
        @variable_table ||= VariableTable.new(self)
      end

      # Starting point.
      def investigate(processed_source)
        root_node = processed_source.ast
        return unless root_node

        variable_table.push_scope(root_node)
        process_node(root_node)
        variable_table.pop_scope
      end

      def process_node(node)
        method_name = node_handler_method_name(node)
        retval = send(method_name, node) if method_name
        process_children(node) unless retval == :skip_children
      end

      private

      # This is called for each scope recursively.
      def inspect_variables_in_scope(scope_node)
        variable_table.push_scope(scope_node)
        process_children(scope_node)
        variable_table.pop_scope
      end

      def process_children(origin_node)
        origin_node.each_child_node do |child_node|
          next if scanned_node?(child_node)

          process_node(child_node)
        end
      end

      def skip_children!
        :skip_children
      end

      NODE_HANDLER_METHOD_NAMES = [
        [VARIABLE_ASSIGNMENT_TYPE, :process_variable_assignment],
        [REGEXP_NAMED_CAPTURE_TYPE, :process_regexp_named_captures],
        [PATTERN_MATCH_VARIABLE_TYPE, :process_pattern_match_variable],
        [MULTIPLE_ASSIGNMENT_TYPE, :process_variable_multiple_assignment],
        [VARIABLE_REFERENCE_TYPE, :process_variable_referencing],
        [RESCUE_TYPE, :process_rescue],
        [ZERO_ARITY_SUPER_TYPE, :process_zero_arity_super],
        [SEND_TYPE, :process_send],
        *ARGUMENT_DECLARATION_TYPES.product([:process_variable_declaration]),
        *OPERATOR_ASSIGNMENT_TYPES.product([:process_variable_operator_assignment]),
        *LOOP_TYPES.product([:process_loop]),
        *SCOPE_TYPES.product([:process_scope])
      ].to_h.freeze
      private_constant :NODE_HANDLER_METHOD_NAMES
      def node_handler_method_name(node)
        NODE_HANDLER_METHOD_NAMES[node.type]
      end

      def process_variable_declaration(node)
        variable_name = node.children.first

        # restarg and kwrestarg would have no name:
        #
        #   def initialize(*)
        #   end
        return unless variable_name

        variable_table.declare_variable(variable_name, node)
      end

      def process_variable_assignment(node)
        name = node.children.first

        variable_table.declare_variable(name, node) unless variable_table.variable_exist?(name)

        # Need to scan rhs before assignment so that we can mark previous
        # assignments as referenced if rhs has referencing to the variable
        # itself like:
        #
        #   foo = 1
        #   foo = foo + 1
        process_children(node)

        variable_table.assign_to_variable(name, node)

        skip_children!
      end

      def process_regexp_named_captures(node)
        regexp_node, rhs_node = *node
        variable_names = regexp_captured_names(regexp_node)

        variable_names.each do |name|
          next if variable_table.variable_exist?(name)

          variable_table.declare_variable(name, node)
        end

        process_node(rhs_node)
        process_node(regexp_node)

        variable_names.each { |name| variable_table.assign_to_variable(name, node) }

        skip_children!
      end

      def process_pattern_match_variable(node)
        name = node.children.first

        variable_table.declare_variable(name, node) unless variable_table.variable_exist?(name)

        skip_children!
      end

      def regexp_captured_names(node)
        regexp = node.to_regexp

        regexp.named_captures.keys
      end

      def process_variable_operator_assignment(node)
        asgn_node = node.lhs
        return unless asgn_node.lvasgn_type?

        name = asgn_node.name

        variable_table.declare_variable(name, asgn_node) unless variable_table.variable_exist?(name)

        # The following statements:
        #
        #   foo = 1
        #   foo += foo = 2
        #   # => 3
        #
        # are equivalent to:
        #
        #   foo = 1
        #   foo = foo + (foo = 2)
        #   # => 3
        #
        # So, at operator assignment node, we need to reference the variable
        # before processing rhs nodes.

        variable_table.reference_variable(name, node)
        process_node(node.rhs)
        variable_table.assign_to_variable(name, asgn_node)

        skip_children!
      end

      def process_variable_multiple_assignment(node)
        lhs_node, rhs_node = *node
        process_node(rhs_node)
        process_node(lhs_node)
        skip_children!
      end

      def process_variable_referencing(node)
        name = node.children.first
        variable_table.reference_variable(name, node)
      end

      def process_loop(node)
        if POST_CONDITION_LOOP_TYPES.include?(node.type)
          # See the comment at the end of file for this behavior.
          condition_node, body_node = *node
          process_node(body_node)
          process_node(condition_node)
        else
          process_children(node)
        end

        mark_assignments_as_referenced_in_loop(node)

        skip_children!
      end

      def process_rescue(node)
        resbody_nodes = node.each_child_node(:resbody)

        contain_retry = resbody_nodes.any? do |resbody_node|
          resbody_node.each_descendant.any?(&:retry_type?)
        end

        # Treat begin..rescue..end with retry as a loop.
        process_loop(node) if contain_retry
      end

      def process_zero_arity_super(node)
        variable_table.accessible_variables.each do |variable|
          next unless variable.method_argument?

          variable.reference!(node)
        end
      end

      def process_scope(node)
        if TWISTED_SCOPE_TYPES.include?(node.type)
          # See the comment at the end of file for this behavior.
          twisted_nodes(node).each do |twisted_node|
            process_node(twisted_node)
            scanned_nodes << twisted_node
          end
        end

        inspect_variables_in_scope(node)
        skip_children!
      end

      def twisted_nodes(node)
        twisted_nodes = [node.children[0]]
        twisted_nodes << node.children[1] if node.class_type?
        twisted_nodes.compact
      end

      def process_send(node)
        _receiver, method_name, args = *node
        return unless method_name == :binding
        return if args && !args.children.empty?

        variable_table.accessible_variables.each { |variable| variable.reference!(node) }
      end

      # Mark all assignments which are referenced in the same loop
      # as referenced by ignoring AST order since they would be referenced
      # in next iteration.
      def mark_assignments_as_referenced_in_loop(node)
        referenced_variable_names_in_loop, assignment_nodes_in_loop = find_variables_in_loop(node)

        referenced_variable_names_in_loop.each do |name|
          variable = variable_table.find_variable(name)
          # Non related references which are caught in the above scan
          # would be skipped here.
          next unless variable

          variable.assignments.each do |assignment|
            next if assignment_nodes_in_loop.none? do |assignment_node|
                      assignment_node.equal?(assignment.node)
                    end

            assignment.reference!(node)
          end
        end
      end

      def find_variables_in_loop(loop_node)
        referenced_variable_names_in_loop = []
        assignment_nodes_in_loop = []

        each_descendant_reference(loop_node) do |reference|
          if reference.assignment?
            assignment_nodes_in_loop << reference.node
          else
            referenced_variable_names_in_loop << reference.name
          end
        end

        [referenced_variable_names_in_loop, assignment_nodes_in_loop]
      end

      def each_descendant_reference(loop_node)
        # #each_descendant does not consider scope,
        # but we don't need to care about it here.
        loop_node.each_descendant do |node|
          reference = descendant_reference(node)

          yield reference if reference
        end
      end

      def descendant_reference(node)
        case node.type
        when :lvar
          VariableReference.new(node.children.first)
        when :lvasgn
          AssignmentReference.new(node)
        when *OPERATOR_ASSIGNMENT_TYPES
          VariableReference.new(node.lhs.name) if node.lhs.lvasgn_type?
        end
      end

      def scanned_node?(node)
        scanned_nodes.include?(node)
      end

      def scanned_nodes
        @scanned_nodes ||= Set.new.compare_by_identity
      end

      # Hooks invoked by VariableTable.
      %i[
        before_entering_scope
        after_entering_scope
        before_leaving_scope
        after_leaving_scope
        before_declaring_variable
        after_declaring_variable
      ].each do |hook|
        define_method(hook) do |arg|
          # Invoke hook in cops.
          run_hook(hook, arg, variable_table)
        end
      end

      # Post condition loops
      #
      # Loop body nodes need to be scanned first.
      #
      # Ruby:
      #   begin
      #     foo = 1
      #   end while foo > 10
      #   puts foo
      #
      # AST:
      #   (begin
      #     (while-post
      #       (send
      #         (lvar :foo) :>
      #         (int 10))
      #       (kwbegin
      #         (lvasgn :foo
      #           (int 1))))
      #     (send nil :puts
      #       (lvar :foo)))

      # Twisted scope types
      #
      # The variable foo belongs to the top level scope,
      # but in AST, it's under the block node.
      #
      # Ruby:
      #   some_method(foo = 1) do
      #   end
      #   puts foo
      #
      # AST:
      #   (begin
      #     (block
      #       (send nil :some_method
      #         (lvasgn :foo
      #           (int 1)))
      #       (args) nil)
      #     (send nil :puts
      #       (lvar :foo)))
      #
      # So the method argument nodes need to be processed
      # in current scope.
      #
      # Same thing.
      #
      # Ruby:
      #   instance = Object.new
      #   class << instance
      #     foo = 1
      #   end
      #
      # AST:
      #   (begin
      #     (lvasgn :instance
      #       (send
      #         (const nil :Object) :new))
      #     (sclass
      #       (lvar :instance)
      #       (begin
      #         (lvasgn :foo
      #           (int 1))
    end
  end
end
