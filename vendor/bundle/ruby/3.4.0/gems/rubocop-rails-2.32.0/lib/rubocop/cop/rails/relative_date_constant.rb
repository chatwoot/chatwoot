# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks whether constant value isn't relative date.
      # Because the relative date will be evaluated only once.
      #
      # @safety
      #   This cop's autocorrection is unsafe because its dependence on the constant is not corrected.
      #
      # @example
      #   # bad
      #   class SomeClass
      #     EXPIRED_AT = 1.week.since
      #   end
      #
      #   # good
      #   class SomeClass
      #     EXPIRES = 1.week
      #
      #     def self.expired_at
      #       EXPIRES.since
      #     end
      #   end
      #
      #   # good
      #   class SomeClass
      #     def self.expired_at
      #       1.week.since
      #     end
      #   end
      class RelativeDateConstant < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not assign `%<method_name>s` to constants as it will be evaluated only once.'
        RELATIVE_DATE_METHODS = %i[since from_now after ago until before yesterday tomorrow].to_set.freeze

        def on_casgn(node)
          nested_relative_date(node) do |method_name|
            add_offense(node, message: message(method_name)) do |corrector|
              autocorrect(corrector, node)
            end
          end
        end

        def on_masgn(node)
          lhs, rhs = *node

          return unless rhs&.array_type?

          lhs.children.zip(rhs.children).each do |(name, value)|
            next unless name.casgn_type?

            nested_relative_date(value) do |method_name|
              add_offense(offense_range(name, value), message: message(method_name)) do |corrector|
                autocorrect(corrector, node)
              end
            end
          end
        end

        def on_or_asgn(node)
          relative_date_or_assignment(node) do |method_name|
            add_offense(node, message: format(MSG, method_name: method_name))
          end
        end

        private

        def autocorrect(corrector, node)
          return unless node.casgn_type?

          scope, const_name, value = *node
          return unless scope.nil?

          indent = ' ' * node.loc.column
          new_code = ["def self.#{const_name.downcase}", "#{indent}#{value.source}", 'end'].join("\n#{indent}")

          corrector.replace(node, new_code)
        end

        def message(method_name)
          format(MSG, method_name: method_name)
        end

        def offense_range(name, value)
          range_between(name.source_range.begin_pos, value.source_range.end_pos)
        end

        def nested_relative_date(node, &callback)
          return if node.nil? || node.any_block_type?

          node.each_child_node do |child|
            nested_relative_date(child, &callback)
          end

          relative_date(node, &callback)
        end

        def_node_matcher :relative_date_or_assignment, <<~PATTERN
          (:or_asgn (casgn _ _) (send _ $RELATIVE_DATE_METHODS))
        PATTERN

        def_node_matcher :relative_date, <<~PATTERN
          (send _ $RELATIVE_DATE_METHODS)
        PATTERN
      end
    end
  end
end
