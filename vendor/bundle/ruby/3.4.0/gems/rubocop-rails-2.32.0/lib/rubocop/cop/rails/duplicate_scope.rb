# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for multiple scopes in a model that have the same `where` clause. This
      # often means you copy/pasted a scope, updated the name, and forgot to change the condition.
      #
      # @example
      #
      #   # bad
      #   scope :visible, -> { where(visible: true) }
      #   scope :hidden, -> { where(visible: true) }
      #
      #   # good
      #   scope :visible, -> { where(visible: true) }
      #   scope :hidden, -> { where(visible: false) }
      #
      class DuplicateScope < Base
        include ClassSendNodeHelper

        MSG = 'Multiple scopes share this same where clause.'

        def_node_matcher :scope, <<~PATTERN
          (send nil? :scope _ $...)
        PATTERN

        def on_class(class_node)
          offenses(class_node).each do |node|
            add_offense(node)
          end
        end

        private

        def offenses(class_node)
          class_send_nodes(class_node).select { |node| scope(node) }
                                      .group_by { |node| scope(node) }
                                      .select { |_, nodes| nodes.length > 1 }
                                      .values
                                      .flatten
        end
      end
    end
  end
end
