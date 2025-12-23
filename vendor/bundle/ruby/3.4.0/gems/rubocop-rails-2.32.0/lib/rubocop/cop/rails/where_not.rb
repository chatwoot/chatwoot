# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies places where manually constructed SQL
      # in `where` can be replaced with `where.not(...)`.
      #
      # @example
      #   # bad
      #   User.where('name != ?', 'Gabe')
      #   User.where('name != :name', name: 'Gabe')
      #   User.where('name <> ?', 'Gabe')
      #   User.where('name <> :name', name: 'Gabe')
      #   User.where('name IS NOT NULL')
      #   User.where('name NOT IN (?)', ['john', 'jane'])
      #   User.where('name NOT IN (:names)', names: ['john', 'jane'])
      #   User.where('users.name != :name', name: 'Gabe')
      #
      #   # good
      #   User.where.not(name: 'Gabe')
      #   User.where.not(name: nil)
      #   User.where.not(name: ['john', 'jane'])
      #   User.where.not(users: { name: 'Gabe' })
      #
      class WhereNot < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<good_method>s` instead of manually constructing negated SQL in `where`.'
        RESTRICT_ON_SEND = %i[where].freeze

        def_node_matcher :where_method_call?, <<~PATTERN
          {
            (call _ :where (array $str_type? $_ ?))
            (call _ :where $str_type? $_ ?)
          }
        PATTERN

        def on_send(node)
          where_method_call?(node) do |template_node, value_node|
            value_node = value_node.first

            range = offense_range(node)

            column, value = extract_column_and_value(template_node, value_node)
            return unless value

            good_method = build_good_method(node.loc.dot&.source, column, value)
            message = format(MSG, good_method: good_method)

            add_offense(range, message: message) do |corrector|
              corrector.replace(range, good_method)
            end
          end
        end
        alias on_csend on_send

        NOT_EQ_ANONYMOUS_RE = /\A([\w.]+)\s+(?:!=|<>)\s+\?\z/.freeze           # column != ?, column <> ?
        NOT_IN_ANONYMOUS_RE = /\A([\w.]+)\s+NOT\s+IN\s+\(\?\)\z/i.freeze       # column NOT IN (?)
        NOT_EQ_NAMED_RE     = /\A([\w.]+)\s+(?:!=|<>)\s+:(\w+)\z/.freeze       # column != :column, column <> :column
        NOT_IN_NAMED_RE     = /\A([\w.]+)\s+NOT\s+IN\s+\(:(\w+)\)\z/i.freeze   # column NOT IN (:column)
        IS_NOT_NULL_RE      = /\A([\w.]+)\s+IS\s+NOT\s+NULL\z/i.freeze         # column IS NOT NULL

        private

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        def extract_column_and_value(template_node, value_node)
          value =
            case template_node.value
            when NOT_EQ_ANONYMOUS_RE, NOT_IN_ANONYMOUS_RE
              value_node&.source
            when NOT_EQ_NAMED_RE, NOT_IN_NAMED_RE
              return unless value_node&.hash_type?

              pair = value_node.pairs.find { |p| p.key.value.to_sym == Regexp.last_match(2).to_sym }
              pair.value.source
            when IS_NOT_NULL_RE
              'nil'
            else
              return
            end

          column_qualifier = Regexp.last_match(1)
          return if column_qualifier.count('.') > 1

          [column_qualifier, value]
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

        def build_good_method(dot, column, value)
          dot ||= '.'
          if column.include?('.')
            table, column = column.split('.')

            "where#{dot}not(#{table}: { #{column}: #{value} })"
          else
            "where#{dot}not(#{column}: #{value})"
          end
        end
      end
    end
  end
end
