# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces that there is only one call to `after_commit`
      # (and its aliases - `after_create_commit`, `after_update_commit`,
      # and `after_destroy_commit`) with the same callback name per model.
      #
      # @example
      #   # bad
      #   # This won't be triggered.
      #   after_create_commit :log_action
      #
      #   # This will override the callback added by
      #   # after_create_commit.
      #   after_update_commit :log_action
      #
      #   # bad
      #   # This won't be triggered.
      #   after_commit :log_action, on: :create
      #   # This won't be triggered.
      #   after_update_commit :log_action
      #   # This will override both previous callbacks.
      #   after_commit :log_action, on: :destroy
      #
      #   # good
      #   after_save_commit :log_action
      #
      #   # good
      #   after_create_commit :log_create_action
      #   after_update_commit :log_update_action
      #
      class AfterCommitOverride < Base
        include ClassSendNodeHelper

        MSG = 'There can only be one `after_*_commit :%<name>s` hook defined for a model.'

        AFTER_COMMIT_CALLBACKS = %i[
          after_commit
          after_create_commit
          after_update_commit
          after_save_commit
          after_destroy_commit
        ].freeze

        def on_class(class_node)
          seen_callback_names = {}

          each_after_commit_callback(class_node) do |node|
            callback_name = node.first_argument.value
            if seen_callback_names.key?(callback_name)
              add_offense(node, message: format(MSG, name: callback_name))
            else
              seen_callback_names[callback_name] = true
            end
          end
        end

        private

        def each_after_commit_callback(class_node)
          class_send_nodes(class_node).each do |node|
            yield node if after_commit_callback?(node) && named_callback?(node)
          end
        end

        def after_commit_callback?(node)
          AFTER_COMMIT_CALLBACKS.include?(node.method_name)
        end

        def named_callback?(node)
          name = node.first_argument
          return false unless name

          name.sym_type?
        end
      end
    end
  end
end
