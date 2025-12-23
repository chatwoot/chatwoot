# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for associations that have been defined multiple times in the same file.
      #
      # When an association is defined multiple times on a model, Active Record overrides the
      # previously defined association with the new one. Because of this, this cop's autocorrection
      # simply keeps the last of any duplicates and discards the rest.
      #
      # @example
      #
      #   # bad
      #   belongs_to :foo
      #   belongs_to :bar
      #   has_one :foo
      #
      #   # good
      #   belongs_to :bar
      #   has_one :foo
      #
      #   # bad
      #   has_many :foo, class_name: 'Foo'
      #   has_many :bar, class_name: 'Foo'
      #   has_one :baz
      #
      #   # good
      #   has_many :bar, class_name: 'Foo'
      #   has_one :foo
      #
      class DuplicateAssociation < Base
        include RangeHelp
        extend AutoCorrector
        include ClassSendNodeHelper
        include ActiveRecordHelper

        MSG = "Association `%<name>s` is defined multiple times. Don't repeat associations."
        MSG_CLASS_NAME = "Association `class_name: %<name>s` is defined multiple times. Don't repeat associations."

        def_node_matcher :association, <<~PATTERN
          (send nil? {:belongs_to :has_one :has_many :has_and_belongs_to_many} ({sym str} $_) $...)
        PATTERN

        def_node_matcher :class_name, <<~PATTERN
          (hash (pair (sym :class_name) $_))
        PATTERN

        def on_class(class_node)
          return unless active_record?(class_node.parent_class)

          association_nodes = association_nodes(class_node)

          duplicated_association_name_nodes(association_nodes).each do |name, nodes|
            register_offense(name, nodes, MSG)
          end

          duplicated_class_name_nodes(association_nodes).each do |class_name, nodes|
            register_offense(class_name, nodes, MSG_CLASS_NAME)
          end
        end

        private

        def register_offense(name, nodes, message_template)
          last_node = nodes.last

          nodes.each_with_index do |node, index|
            add_offense(node, message: format(message_template, name: name)) do |corrector|
              if index.zero?
                corrector.replace(node, last_node.source)
              else
                corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))
              end
            end
          end
        end

        def association_nodes(class_node)
          class_send_nodes(class_node).select do |node|
            association(node)&.first
          end
        end

        def duplicated_association_name_nodes(association_nodes)
          grouped_associations = association_nodes.group_by do |node|
            association(node).first.to_sym
          end

          leave_duplicated_association(grouped_associations)
        end

        def duplicated_class_name_nodes(association_nodes)
          filtered_nodes = association_nodes.reject { |node| node.method?(:belongs_to) }
          grouped_associations = filtered_nodes.group_by do |node|
            arguments = association(node).last
            next unless arguments.count == 1

            if (class_name = class_name(arguments.first))
              class_name.source
            end
          end

          grouped_associations.delete(nil)

          leave_duplicated_association(grouped_associations)
        end

        def leave_duplicated_association(grouped_associations)
          grouped_associations.select do |_, nodes|
            nodes.length > 1
          end
        end
      end
    end
  end
end
