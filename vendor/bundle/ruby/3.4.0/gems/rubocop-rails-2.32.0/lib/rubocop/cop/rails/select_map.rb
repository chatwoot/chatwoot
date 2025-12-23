# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for uses of `select(:column_name)` with `map(&:column_name)`.
      # These can be replaced with `pluck(:column_name)`.
      #
      # There also should be some performance improvement since it skips instantiating the model class for matches.
      #
      # @safety
      #   This cop is unsafe because the model might override the attribute getter.
      #   Additionally, the model's `after_initialize` hooks are skipped when using `pluck`.
      #
      # @example
      #   # bad
      #   Model.select(:column_name).map(&:column_name)
      #
      #   # good
      #   Model.pluck(:column_name)
      #
      class SelectMap < Base
        extend AutoCorrector

        MSG = 'Use `%<preferred_method>s` instead of `select` with `%<map_method>s`.'

        RESTRICT_ON_SEND = %i[map collect].freeze

        def on_send(node)
          return unless node.first_argument

          column_name = node.first_argument.source.delete_prefix('&:')
          return unless (select_node = find_select_node(node, column_name))

          offense_range = select_node.loc.selector.begin.join(node.source_range.end)
          preferred_method = "pluck(:#{column_name})"
          message = format(MSG, preferred_method: preferred_method, map_method: node.method_name)

          add_offense(offense_range, message: message) do |corrector|
            autocorrect(corrector, select_node, node, preferred_method)
          end
        end
        alias on_csend on_send

        private

        def find_select_node(node, column_name)
          node.descendants.detect do |select_candidate|
            next if !select_candidate.call_type? || !select_candidate.method?(:select)

            match_column_name?(select_candidate, column_name)
          end
        end

        # rubocop:disable Metrics/AbcSize
        def autocorrect(corrector, select_node, node, preferred_method)
          corrector.remove(select_node.parent.loc.dot)
          corrector.remove(select_node.loc.selector.begin.join(select_node.source_range.end))
          corrector.replace(node.loc.selector.begin.join(node.source_range.end), preferred_method)
        end
        # rubocop:enable Metrics/AbcSize

        def match_column_name?(select_candidate, column_name)
          return false unless select_candidate.arguments.one?
          return false unless (first_argument = select_candidate.first_argument)

          argument = case select_candidate.first_argument.type
                     when :sym
                       first_argument.source.delete_prefix(':')
                     when :str
                       first_argument.value if first_argument.respond_to?(:value)
                     end

          argument == column_name
        end
      end
    end
  end
end
