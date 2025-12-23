# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies usages of `where.take` and change them to use `find_by` instead.
      #
      # And `where(...).first` can return different results from `find_by`.
      # (They order records differently, so the "first" record can be different.)
      #
      # If you also want to detect `where.first`, you can set `IgnoreWhereFirst` to false.
      #
      # @example
      #   # bad
      #   User.where(name: 'Bruce').take
      #
      #   # good
      #   User.find_by(name: 'Bruce')
      #
      # @example IgnoreWhereFirst: true (default)
      #   # good
      #   User.where(name: 'Bruce').first
      #
      # @example IgnoreWhereFirst: false
      #   # bad
      #   User.where(name: 'Bruce').first
      class FindBy < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `find_by` instead of `where%<dot>s%<method>s`.'
        RESTRICT_ON_SEND = %i[first take].freeze

        def on_send(node)
          return unless node.arguments.empty? && where_method?(node.receiver)
          return if ignore_where_first? && node.method?(:first)

          range = offense_range(node)

          add_offense(range, message: format(MSG, dot: node.loc.dot.source, method: node.method_name)) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_csend on_send

        private

        def where_method?(receiver)
          return false unless receiver

          receiver.respond_to?(:method?) && receiver.method?(:where)
        end

        def offense_range(node)
          range_between(node.receiver.loc.selector.begin_pos, node.loc.selector.end_pos)
        end

        def autocorrect(corrector, node)
          return if node.method?(:first)

          where_loc = node.receiver.loc.selector
          first_loc = range_between(node.receiver.source_range.end_pos, node.loc.selector.end_pos)

          corrector.replace(where_loc, 'find_by')
          corrector.replace(first_loc, '')
        end

        def ignore_where_first?
          cop_config.fetch('IgnoreWhereFirst', true)
        end
      end
    end
  end
end
