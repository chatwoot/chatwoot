# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant `begin` blocks.
      #
      # Currently it checks for code like this:
      #
      # @example
      #
      #   # bad
      #   def redundant
      #     begin
      #       ala
      #       bala
      #     rescue StandardError => e
      #       something
      #     end
      #   end
      #
      #   # good
      #   def preferred
      #     ala
      #     bala
      #   rescue StandardError => e
      #     something
      #   end
      #
      #   # bad
      #   begin
      #     do_something
      #   end
      #
      #   # good
      #   do_something
      #
      #   # bad
      #   # When using Ruby 2.5 or later.
      #   do_something do
      #     begin
      #       something
      #     rescue => ex
      #       anything
      #     end
      #   end
      #
      #   # good
      #   # In Ruby 2.5 or later, you can omit `begin` in `do-end` block.
      #   do_something do
      #     something
      #   rescue => ex
      #     anything
      #   end
      #
      #   # good
      #   # Stabby lambdas don't support implicit `begin` in `do-end` blocks.
      #   -> do
      #     begin
      #       foo
      #     rescue Bar
      #       baz
      #     end
      #   end
      class RedundantBegin < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Redundant `begin` block detected.'

        def self.autocorrect_incompatible_with
          [Style::BlockDelimiters]
        end

        # @!method offensive_kwbegins(node)
        def_node_search :offensive_kwbegins, <<~PATTERN
          [(kwbegin ...) !#allowable_kwbegin?]
        PATTERN

        def on_def(node)
          return unless node.body&.kwbegin_type?
          return if node.endless?

          register_offense(node.body)
        end
        alias on_defs on_def

        def on_block(node)
          return if target_ruby_version < 2.5
          return if node.send_node.lambda_literal?
          return if node.braces?
          return unless node.body&.kwbegin_type?

          register_offense(node.body)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        def on_kwbegin(node)
          return unless (target_node = offensive_kwbegins(node).to_a.last)

          register_offense(target_node)
        end

        private

        def allowable_kwbegin?(node)
          empty_begin?(node) ||
            begin_block_has_multiline_statements?(node) ||
            contain_rescue_or_ensure?(node) ||
            valid_context_using_only_begin?(node)
        end

        def register_offense(node)
          offense_range = node.loc.begin

          add_offense(offense_range) do |corrector|
            if node.parent&.assignment?
              replace_begin_with_statement(corrector, offense_range, node)
            else
              remove_begin(corrector, offense_range, node)
            end

            if use_modifier_form_after_multiline_begin_block?(node)
              correct_modifier_form_after_multiline_begin_block(corrector, node)
            end
            corrector.remove(node.loc.end)
          end
        end

        def replace_begin_with_statement(corrector, offense_range, node)
          first_child = node.children.first

          source = first_child.source
          source = "(#{source})" if first_child.if_type? && first_child.modifier_form?

          corrector.replace(offense_range, source)
          corrector.remove(range_between(offense_range.end_pos, first_child.source_range.end_pos))

          restore_removed_comments(corrector, offense_range, node, first_child)
        end

        def remove_begin(corrector, offense_range, node)
          if node.parent.respond_to?(:endless?) && node.parent.endless?
            offense_range = range_with_surrounding_space(offense_range, newlines: true)
          end

          corrector.remove(offense_range)
        end

        # Restore comments that occur between "begin" and "first_child".
        # These comments will be moved to above the assignment line.
        def restore_removed_comments(corrector, offense_range, node, first_child)
          comments_range = range_between(offense_range.end_pos, first_child.source_range.begin_pos)
          comments = comments_range.source

          corrector.insert_before(node.parent, comments) unless comments.blank?
        end

        def use_modifier_form_after_multiline_begin_block?(node)
          return false unless (parent = node.parent)

          node.multiline? && parent.if_type? && parent.modifier_form?
        end

        def correct_modifier_form_after_multiline_begin_block(corrector, node)
          condition_range = condition_range(node.parent)

          corrector.insert_after(node.children.first, " #{condition_range.source}")
          corrector.remove(range_by_whole_lines(condition_range, include_final_newline: true))
        end

        def condition_range(node)
          range_between(node.loc.keyword.begin_pos, node.condition.source_range.end_pos)
        end

        def empty_begin?(node)
          node.children.empty?
        end

        def begin_block_has_multiline_statements?(node)
          node.children.count >= 2
        end

        def contain_rescue_or_ensure?(node)
          first_child = node.children.first

          first_child.type?(:rescue, :ensure)
        end

        def valid_context_using_only_begin?(node)
          parent = node.parent

          valid_begin_assignment?(node) || parent&.post_condition_loop? ||
            parent&.send_type? || parent&.operator_keyword?
        end

        def valid_begin_assignment?(node)
          node.parent&.assignment? && !node.children.one?
        end
      end
    end
  end
end
