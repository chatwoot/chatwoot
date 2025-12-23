# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies places where manually constructed SQL
      # in `where` and `where.not` can be replaced with
      # `where(attribute: value)` and `where.not(attribute: value)`.
      #
      # @safety
      #   This cop's autocorrection is unsafe because is may change SQL.
      #   See: https://github.com/rubocop/rubocop-rails/issues/403
      #
      # @example
      #   # bad
      #   User.where('name = ?', 'Gabe')
      #   User.where.not('name = ?', 'Gabe')
      #   User.where('name = :name', name: 'Gabe')
      #   User.where('name IS NULL')
      #   User.where('name IN (?)', ['john', 'jane'])
      #   User.where('name IN (:names)', names: ['john', 'jane'])
      #   User.where('users.name = :name', name: 'Gabe')
      #
      #   # good
      #   User.where(name: 'Gabe')
      #   User.where.not(name: 'Gabe')
      #   User.where(name: nil)
      #   User.where(name: ['john', 'jane'])
      #   User.where(users: { name: 'Gabe' })
      class WhereEquals < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<good_method>s` instead of manually constructing SQL.'
        RESTRICT_ON_SEND = %i[where not].freeze

        def_node_matcher :where_method_call?, <<~PATTERN
          {
            (call _ {:where :not} (array $str_type? $_ ?))
            (call _ {:where :not} $str_type? $_ ?)
          }
        PATTERN

        def on_send(node)
          return if node.method?(:not) && !where_not?(node)

          where_method_call?(node) do |template_node, value_node|
            value_node = value_node.first

            range = offense_range(node)

            column, value = extract_column_and_value(template_node, value_node)
            return unless value

            good_method = build_good_method(node.method_name, column, value)
            message = format(MSG, good_method: good_method)

            add_offense(range, message: message) do |corrector|
              corrector.replace(range, good_method)
            end
          end
        end
        alias on_csend on_send

        EQ_ANONYMOUS_RE = /\A([\w.]+)\s+=\s+\?\z/.freeze             # column = ?
        IN_ANONYMOUS_RE = /\A([\w.]+)\s+IN\s+\(\?\)\z/i.freeze       # column IN (?)
        EQ_NAMED_RE     = /\A([\w.]+)\s+=\s+:(\w+)\z/.freeze         # column = :column
        IN_NAMED_RE     = /\A([\w.]+)\s+IN\s+\(:(\w+)\)\z/i.freeze   # column IN (:column)
        IS_NULL_RE      = /\A([\w.]+)\s+IS\s+NULL\z/i.freeze         # column IS NULL

        private

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        def extract_column_and_value(template_node, value_node)
          value =
            case template_node.value
            when EQ_ANONYMOUS_RE, IN_ANONYMOUS_RE
              value_node&.source
            when EQ_NAMED_RE, IN_NAMED_RE
              return unless value_node&.hash_type?

              pair = value_node.pairs.find { |p| p.key.value.to_sym == Regexp.last_match(2).to_sym }
              pair.value.source
            when IS_NULL_RE
              'nil'
            else
              return
            end

          column_qualifier = Regexp.last_match(1)
          return if column_qualifier.count('.') > 1

          [column_qualifier, value]
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

        def build_good_method(method_name, column, value)
          if column.include?('.')
            table, column = column.split('.')

            "#{method_name}(#{table}: { #{column}: #{value} })"
          else
            "#{method_name}(#{column}: #{value})"
          end
        end

        def where_not?(node)
          return false unless (receiver = node.receiver)

          receiver.send_type? && receiver.method?(:where)
        end
      end
    end
  end
end
