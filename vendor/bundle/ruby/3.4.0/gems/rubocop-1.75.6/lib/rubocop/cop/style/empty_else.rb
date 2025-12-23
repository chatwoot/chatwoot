# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for empty else-clauses, possibly including comments and/or an
      # explicit `nil` depending on the EnforcedStyle.
      #
      # @example EnforcedStyle: both (default)
      #   # warn on empty else and else with nil in it
      #
      #   # bad
      #   if condition
      #     statement
      #   else
      #     nil
      #   end
      #
      #   # bad
      #   if condition
      #     statement
      #   else
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     statement
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   end
      #
      # @example EnforcedStyle: empty
      #   # warn only on empty else
      #
      #   # bad
      #   if condition
      #     statement
      #   else
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     nil
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     statement
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   end
      #
      # @example EnforcedStyle: nil
      #   # warn on else with nil in it
      #
      #   # bad
      #   if condition
      #     statement
      #   else
      #     nil
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     statement
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   end
      #
      # @example AllowComments: false (default)
      #
      #   # bad
      #   if condition
      #     statement
      #   else
      #     # something comment
      #     nil
      #   end
      #
      #   # bad
      #   if condition
      #     statement
      #   else
      #     # something comment
      #   end
      #
      # @example AllowComments: true
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     # something comment
      #     nil
      #   end
      #
      #   # good
      #   if condition
      #     statement
      #   else
      #     # something comment
      #   end
      #
      class EmptyElse < Base
        include OnNormalIfUnless
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = 'Redundant `else`-clause.'
        NIL_STYLES = %i[nil both].freeze
        EMPTY_STYLES = %i[empty both].freeze

        def on_normal_if_unless(node)
          check(node)
        end

        def on_case(node)
          check(node)
        end

        private

        def check(node)
          return if cop_config['AllowComments'] && comment_in_else?(node)

          empty_check(node) if empty_style?
          nil_check(node) if nil_style?
        end

        def nil_style?
          NIL_STYLES.include?(style)
        end

        def empty_style?
          EMPTY_STYLES.include?(style)
        end

        def empty_check(node)
          return unless node.else? && !node.else_branch

          add_offense(node.loc.else) { |corrector| autocorrect(corrector, node) }
        end

        def nil_check(node)
          return unless node.else_branch&.nil_type?

          add_offense(node.loc.else) { |corrector| autocorrect(corrector, node) }
        end

        def autocorrect(corrector, node)
          return false if autocorrect_forbidden?(node.type.to_s)
          return false if comment_in_else?(node)

          end_pos = base_node(node).loc.end.begin_pos
          corrector.remove(range_between(node.loc.else.begin_pos, end_pos))
        end

        def comment_in_else?(node)
          node = node.parent while node.if_type? && node.elsif?
          return false unless node.else?

          processed_source.contains_comment?(node.loc.else.join(node.source_range.end))
        end

        def base_node(node)
          return node if node.case_type?
          return node unless node.elsif?

          node.each_ancestor(:if, :case, :when).find(-> { node }) { |parent| parent.loc.end }
        end

        def autocorrect_forbidden?(type)
          [type, 'both'].include?(missing_else_style)
        end

        def missing_else_style
          missing_cfg = config.for_cop('Style/MissingElse')
          missing_cfg.fetch('Enabled') ? missing_cfg['EnforcedStyle'] : nil
        end
      end
    end
  end
end
