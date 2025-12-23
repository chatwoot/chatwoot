# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies possible cases where Active Record save! or related
      # should be used instead of save because the model might have failed to
      # save and an exception is better than unhandled failure.
      #
      # This will allow:
      #
      # * update or save calls, assigned to a variable,
      #   or used as a condition in an if/unless/case statement.
      # * create calls, assigned to a variable that then has a
      #   call to `persisted?`, or whose return value is checked by
      #   `persisted?` immediately
      # * calls if the result is explicitly returned from methods and blocks,
      #   or provided as arguments.
      # * calls whose signature doesn't look like an ActiveRecord
      #   persistence method.
      #
      # By default it will also allow implicit returns from methods and blocks.
      # that behavior can be turned off with `AllowImplicitReturn: false`.
      #
      # You can permit receivers that are giving false positives with
      # `AllowedReceivers: []`
      #
      # @safety
      #   This cop's autocorrection is unsafe because a custom `update` method call would be changed to `update!`,
      #   but the method name in the definition would be unchanged.
      #
      #   [source,ruby]
      #   ----
      #   # Original code
      #   def update_attributes
      #   end
      #
      #   update_attributes
      #
      #   # After running rubocop --safe-autocorrect
      #   def update_attributes
      #   end
      #
      #   update
      #   ----
      #
      # @example
      #
      #   # bad
      #   user.save
      #   user.update(name: 'Joe')
      #   user.find_or_create_by(name: 'Joe')
      #   user.destroy
      #
      #   # good
      #   unless user.save
      #     # ...
      #   end
      #   user.save!
      #   user.update!(name: 'Joe')
      #   user.find_or_create_by!(name: 'Joe')
      #   user.destroy!
      #
      #   user = User.find_or_create_by(name: 'Joe')
      #   unless user.persisted?
      #     # ...
      #   end
      #
      #   def save_user
      #     return user.save
      #   end
      #
      # @example AllowImplicitReturn: true (default)
      #
      #   # good
      #   users.each { |u| u.save }
      #
      #   def save_user
      #     user.save
      #   end
      #
      # @example AllowImplicitReturn: false
      #
      #   # bad
      #   users.each { |u| u.save }
      #   def save_user
      #     user.save
      #   end
      #
      #   # good
      #   users.each { |u| u.save! }
      #
      #   def save_user
      #     user.save!
      #   end
      #
      #   def save_user
      #     return user.save
      #   end
      #
      # @example AllowedReceivers: ['merchant.customers', 'Service::Mailer']
      #
      #   # bad
      #   merchant.create
      #   customers.builder.save
      #   Mailer.create
      #
      #   module Service::Mailer
      #     self.create
      #   end
      #
      #   # good
      #   merchant.customers.create
      #   MerchantService.merchant.customers.destroy
      #   Service::Mailer.update(message: 'Message')
      #   ::Service::Mailer.update
      #   Services::Service::Mailer.update(message: 'Message')
      #   Service::Mailer::update
      #
      class SaveBang < Base
        include NegativeConditional
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s` if the return value is not checked.'
        CREATE_MSG = "#{MSG} Or check `persisted?` on model returned from `%<current>s`."
        CREATE_CONDITIONAL_MSG = '`%<current>s` returns a model which is always truthy.'

        CREATE_PERSIST_METHODS = %i[create create_or_find_by first_or_create find_or_create_by].freeze
        MODIFY_PERSIST_METHODS = %i[save update update_attributes destroy].freeze
        RESTRICT_ON_SEND = (CREATE_PERSIST_METHODS + MODIFY_PERSIST_METHODS).freeze

        def self.joining_forces
          VariableForce
        end

        def after_leaving_scope(scope, _variable_table)
          scope.variables.each_value do |variable|
            variable.assignments.each do |assignment|
              check_assignment(assignment)
            end
          end
        end

        def check_assignment(assignment)
          node = right_assignment_node(assignment)

          return unless node&.send_type?
          return unless persist_method?(node, CREATE_PERSIST_METHODS)
          return if persisted_referenced?(assignment)

          register_offense(node, CREATE_MSG)
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def on_send(node)
          return unless persist_method?(node)
          return if return_value_assigned?(node)
          return if implicit_return?(node)
          return if check_used_in_condition_or_compound_boolean(node)
          return if argument?(node)
          return if explicit_return?(node)
          return if checked_immediately?(node)

          register_offense(node, MSG)
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        alias on_csend on_send

        private

        def register_offense(node, msg)
          current_method = node.method_name
          bang_method = "#{current_method}!"
          full_message = format(msg, prefer: bang_method, current: current_method)

          range = node.loc.selector
          add_offense(range, message: full_message) do |corrector|
            corrector.replace(range, bang_method)
          end
        end

        def right_assignment_node(assignment)
          node = assignment.node.child_nodes.first

          return node unless node&.any_block_type?

          node.send_node
        end

        def persisted_referenced?(assignment)
          return false unless assignment.referenced?

          assignment.variable.references.any? do |reference|
            call_to_persisted?(reference.node.parent)
          end
        end

        def call_to_persisted?(node)
          node = node.parent.condition if node.parenthesized_call? && node.parent.if_type?

          node.send_type? && node.method?(:persisted?)
        end

        def assignable_node(node)
          assignable = node.block_node || node
          while node
            node = hash_parent(node) || array_parent(node)
            assignable = node if node
          end
          assignable
        end

        def hash_parent(node)
          pair = node.parent
          return unless pair&.pair_type?

          hash = pair.parent
          return unless hash&.hash_type?

          hash
        end

        def array_parent(node)
          array = node.parent
          return unless array&.array_type?

          array
        end

        def check_used_in_condition_or_compound_boolean(node)
          return false unless in_condition_or_compound_boolean?(node)

          register_offense(node, CREATE_CONDITIONAL_MSG) unless MODIFY_PERSIST_METHODS.include?(node.method_name)

          true
        end

        def in_condition_or_compound_boolean?(node)
          node = node.block_node || node
          parent = node.each_ancestor.find { |ancestor| !ancestor.begin_type? }
          return false unless parent

          operator_or_single_negative?(parent) || (conditional?(parent) && node == deparenthesize(parent.condition))
        end

        def operator_or_single_negative?(node)
          node.operator_keyword? || single_negative?(node)
        end

        def conditional?(parent)
          parent.type?(:if, :case)
        end

        def deparenthesize(node)
          node = node.children.last while node.begin_type?
          node
        end

        def checked_immediately?(node)
          node.parent && call_to_persisted?(node.parent)
        end

        def allowed_receiver?(node)
          return false unless node.receiver
          return true if node.receiver.const_name == 'ENV'
          return false unless cop_config['AllowedReceivers']

          cop_config['AllowedReceivers'].any? do |allowed_receiver|
            receiver_chain_matches?(node, allowed_receiver)
          end
        end

        def receiver_chain_matches?(node, allowed_receiver)
          allowed_receiver.split('.').reverse.all? do |receiver_part|
            node = node.receiver
            return false unless node

            if node.variable?
              node.node_parts.first == receiver_part.to_sym
            elsif node.send_type?
              node.method?(receiver_part.to_sym)
            elsif node.const_type?
              const_matches?(node.const_name, receiver_part)
            end
          end
        end

        # Const == Const
        # ::Const == ::Const
        # ::Const == Const
        # Const == ::Const
        # NameSpace::Const == Const
        # NameSpace::Const == NameSpace::Const
        # NameSpace::Const != ::Const
        # Const != NameSpace::Const
        def const_matches?(const, allowed_const)
          parts = allowed_const.split('::').reverse.zip(const.split('::').reverse)
          parts.all? do |(allowed_part, const_part)|
            allowed_part == const_part.to_s
          end
        end

        def implicit_return?(node)
          return false unless cop_config['AllowImplicitReturn']

          node = assignable_node(node)
          method, sibling_index = find_method_with_sibling_index(node.parent)
          return false unless method&.type?(:def, :any_block)

          method.children.size == node.sibling_index + sibling_index
        end

        def find_method_with_sibling_index(node, sibling_index = 1)
          return node, sibling_index unless node&.or_type?

          sibling_index += 1

          find_method_with_sibling_index(node.parent, sibling_index)
        end

        def argument?(node)
          assignable_node(node).argument?
        end

        def explicit_return?(node)
          ret = assignable_node(node).parent
          ret&.type?(:return, :next)
        end

        def return_value_assigned?(node)
          return false unless (assignment = assignable_node(node).parent)

          assignment.assignment?
        end

        def persist_method?(node, methods = RESTRICT_ON_SEND)
          methods.include?(node.method_name) && expected_signature?(node) && !allowed_receiver?(node)
        end

        # Check argument signature as no arguments or one hash
        def expected_signature?(node)
          return true unless node.arguments?
          return false if !node.arguments.one? || node.method?(:destroy)

          node.first_argument.hash_type? || !node.first_argument.literal?
        end
      end
    end
  end
end
