# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the use of exit statements (namely `return`,
      # `break` and `throw`) in transactions. This is due to the eventual
      # unexpected behavior when using ActiveRecord >= 7, where transactions
      # exited using these statements are being rollbacked rather than
      # committed (pre ActiveRecord 7 behavior).
      #
      # As alternatives, it would be more intuitive to explicitly raise an
      # error when rollback is desired, and to use `next` when commit is
      # desired.
      #
      # If you are defining custom transaction methods, you can configure it with `TransactionMethods`.
      #
      # NOTE: This cop is disabled on Rails >= 7.2 because transactions were restored
      # to their historical behavior. In Rails 7.1, the behavior is controlled with
      # the config `active_record.commit_transaction_on_non_local_return`.
      #
      # @example
      #   # bad
      #   ApplicationRecord.transaction do
      #     return if user.active?
      #   end
      #
      #   # bad
      #   ApplicationRecord.transaction do
      #     break if user.active?
      #   end
      #
      #   # bad
      #   ApplicationRecord.transaction do
      #     throw if user.active?
      #   end
      #
      #   # bad, as `with_lock` implicitly opens a transaction too
      #   user.with_lock do
      #     throw if user.active?
      #   end
      #
      #   # bad, as `with_lock` implicitly opens a transaction too
      #   ApplicationRecord.with_lock do
      #     break if user.active?
      #   end
      #
      #   # good
      #   ApplicationRecord.transaction do
      #     # Rollback
      #     raise "User is active" if user.active?
      #   end
      #
      #   # good
      #   ApplicationRecord.transaction do
      #     # Commit
      #     next if user.active?
      #   end
      #
      # @example TransactionMethods: ["custom_transaction"]
      #   # bad
      #   CustomModel.custom_transaction do
      #     return if user.active?
      #   end
      #
      class TransactionExitStatement < Base
        MSG = 'Exit statement `%<statement>s` is not allowed. Use `raise` (rollback) or `next` (commit).'
        BUILT_IN_TRANSACTION_METHODS = %i[transaction with_lock].freeze

        def_node_search :exit_statements, <<~PATTERN
          ({return | break | send nil? :throw} ...)
        PATTERN

        def_node_matcher :rescue_body_return_node?, <<~PATTERN
          (:resbody ...
            ...
            ({return | break | send nil? :throw} ...)
            ...
          )
        PATTERN

        def on_send(node)
          return if target_rails_version >= 7.2
          return unless in_transaction_block?(node)

          exit_statements(node.parent.body).each do |statement_node|
            next if statement_node.break_type? && nested_block?(statement_node)

            statement = statement(statement_node)
            message = format(MSG, statement: statement)

            add_offense(statement_node, message: message)
          end
        end

        private

        def in_transaction_block?(node)
          return false unless transaction_method_name?(node.method_name)
          return false unless (parent = node.parent)

          parent.any_block_type? && parent.body
        end

        def statement(statement_node)
          if statement_node.return_type?
            'return'
          elsif statement_node.break_type?
            'break'
          else
            statement_node.method_name
          end
        end

        def nested_block?(statement_node)
          name = statement_node.ancestors.find(&:any_block_type?).children.first.method_name
          !transaction_method_name?(name)
        end

        def transaction_method_name?(method_name)
          BUILT_IN_TRANSACTION_METHODS.include?(method_name) || transaction_method?(method_name)
        end

        def transaction_method?(method_name)
          cop_config.fetch('TransactionMethods', []).include?(method_name.to_s)
        end
      end
    end
  end
end
