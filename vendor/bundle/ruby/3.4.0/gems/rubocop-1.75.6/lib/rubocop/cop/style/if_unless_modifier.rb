# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for `if` and `unless` statements that would fit on one line if
      # written as modifier `if`/`unless`. The cop also checks for modifier
      # `if`/`unless` lines that exceed the maximum line length.
      #
      # The maximum line length is configured in the `Layout/LineLength`
      # cop. The tab size is configured in the `IndentationWidth` of the
      # `Layout/IndentationStyle` cop.
      #
      # One-line pattern matching is always allowed. To ensure that there are few cases
      # where the match variable is not used, and to prevent oversights. The variable `x`
      # becomes undefined and raises `NameError` when the following example is changed to
      # the modifier form:
      #
      # [source,ruby]
      # ----
      # if [42] in [x]
      #   x # `x` is undefined when using modifier form.
      # end
      # ----
      #
      # The code `def method_name = body if condition` is considered a bad case by
      # `Style/AmbiguousEndlessMethodDefinition` cop. So, to respect the user's intention to use
      # an endless method definition in the `if` body, the following code is allowed:
      #
      # [source,ruby]
      # ----
      # if condition
      #   def method_name = body
      # end
      # ----
      #
      # NOTE: It is allowed when `defined?` argument has an undefined value,
      # because using the modifier form causes the following incompatibility:
      #
      # [source,ruby]
      # ----
      # unless defined?(undefined_foo)
      #   undefined_foo = 'default_value'
      # end
      # undefined_foo # => 'default_value'
      #
      # undefined_bar = 'default_value' unless defined?(undefined_bar)
      # undefined_bar # => nil
      # ----
      #
      # @example
      #   # bad
      #   if condition
      #     do_stuff(bar)
      #   end
      #
      #   unless qux.empty?
      #     Foo.do_something
      #   end
      #
      #   do_something_with_a_long_name(arg) if long_condition_that_prevents_code_fit_on_single_line
      #
      #   # good
      #   do_stuff(bar) if condition
      #   Foo.do_something unless qux.empty?
      #
      #   if long_condition_that_prevents_code_fit_on_single_line
      #     do_something_with_a_long_name(arg)
      #   end
      #
      #   if short_condition # a long comment that makes it too long if it were just a single line
      #     do_something
      #   end
      class IfUnlessModifier < Base
        include StatementModifier
        include LineLengthHelp
        include AllowedPattern
        include RangeHelp
        include CommentsHelp
        extend AutoCorrector

        MSG_USE_MODIFIER = 'Favor modifier `%<keyword>s` usage when having a ' \
                           'single-line body. Another good alternative is ' \
                           'the usage of control flow `&&`/`||`.'
        MSG_USE_NORMAL = 'Modifier form of `%<keyword>s` makes the line too long.'

        def self.autocorrect_incompatible_with
          [Style::SoleNestedConditional]
        end

        # rubocop:disable Metrics/AbcSize
        def on_if(node)
          return if endless_method?(node.body)

          condition = node.condition
          return if defined_nodes(condition).any? { |n| defined_argument_is_undefined?(node, n) } ||
                    pattern_matching_nodes(condition).any?

          return unless (msg = message(node))

          add_offense(node.loc.keyword, message: format(msg, keyword: node.keyword)) do |corrector|
            next if part_of_ignored_node?(node)

            autocorrect(corrector, node)
            ignore_node(node)
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def endless_method?(body)
          body&.any_def_type? && body.endless?
        end

        def defined_nodes(condition)
          if condition.defined_type?
            [condition]
          else
            condition.each_descendant.select(&:defined_type?)
          end
        end

        def defined_argument_is_undefined?(if_node, defined_node)
          defined_argument = defined_node.first_argument
          return false unless defined_argument.type?(:lvar, :send)

          if_node.left_siblings.none? do |sibling|
            sibling.respond_to?(:lvasgn_type?) && sibling.lvasgn_type? &&
              sibling.name == defined_argument.node_parts[0]
          end
        end

        def pattern_matching_nodes(condition)
          if condition.type?(:match_pattern, :match_pattern_p)
            [condition]
          else
            condition.each_descendant.select do |node|
              node.type?(:match_pattern, :match_pattern_p)
            end
          end
        end

        def message(node)
          if single_line_as_modifier?(node) && !named_capture_in_condition?(node)
            MSG_USE_MODIFIER
          elsif too_long_due_to_modifier?(node)
            MSG_USE_NORMAL
          end
        end

        def autocorrect(corrector, node)
          replacement = if node.modifier_form?
                          replacement_for_modifier_form(corrector, node)
                        else
                          to_modifier_form(node)
                        end
          corrector.replace(node, replacement)
        end

        def replacement_for_modifier_form(corrector, node) # rubocop:disable Metrics/AbcSize
          comment = comment_on_node_line(node)
          if comment && too_long_due_to_comment_after_modifier?(node, comment)
            remove_comment(corrector, node, comment)

            return to_modifier_form_with_move_comment(node, indent(node), comment)
          end

          last_argument = node.if_branch.last_argument if node.if_branch.send_type?
          if last_argument.respond_to?(:heredoc?) && last_argument.heredoc?
            heredoc = extract_heredoc_from(last_argument)
            remove_heredoc(corrector, heredoc)

            return to_normal_form_with_heredoc(node, indent(node), heredoc)
          end

          to_normal_form(node, indent(node))
        end

        def too_long_due_to_modifier?(node)
          node.modifier_form? && too_long_single_line?(node) &&
            !another_statement_on_same_line?(node)
        end

        def too_long_due_to_comment_after_modifier?(node, comment)
          source_length = processed_source.lines[node.first_line - 1].length

          max_line_length.between?(source_length - comment.source_range.length, source_length)
        end

        def allowed_patterns
          line_length_config = config.for_cop('Layout/LineLength')
          line_length_config['AllowedPatterns'] || line_length_config['IgnoredPatterns'] || []
        end

        def too_long_single_line?(node)
          return false unless max_line_length

          range = node.source_range
          return false unless range.single_line?
          return false unless line_length_enabled_at_line?(range.first_line)

          line = range.source_line
          return false if line_length(line) <= max_line_length

          too_long_line_based_on_config?(range, line)
        end

        def too_long_line_based_on_config?(range, line)
          return false if matches_allowed_pattern?(line)

          too_long = too_long_line_based_on_ignore_cop_directives?(range, line)
          return too_long unless too_long == :undetermined

          too_long_line_based_on_allow_uri?(line)
        end

        def too_long_line_based_on_ignore_cop_directives?(range, line)
          if ignore_cop_directives? && directive_on_source_line?(range.line - 1)
            return line_length_without_directive(line) > max_line_length
          end

          :undetermined
        end

        def too_long_line_based_on_allow_uri?(line)
          if allow_uri?
            uri_range = find_excessive_uri_range(line)
            return false if uri_range && allowed_uri_position?(line, uri_range)
          end

          true
        end

        def line_length_enabled_at_line?(line)
          processed_source.comment_config.cop_enabled_at_line?('Layout/LineLength', line)
        end

        def named_capture_in_condition?(node)
          node.condition.match_with_lvasgn_type?
        end

        def non_eligible_node?(node)
          non_simple_if_unless?(node) || node.chained? || node.nested_conditional? || super
        end

        def non_simple_if_unless?(node)
          node.ternary? || node.elsif? || node.else?
        end

        def another_statement_on_same_line?(node)
          line_no = node.source_range.last_line

          # traverse the AST upwards until we find a 'begin' node
          # we want to look at the following child and see if it is on the
          #   same line as this 'if' node
          while node && !node.begin_type?
            index = node.sibling_index
            node  = node.parent
          end

          node && (sibling = node.children[index + 1]) && sibling.source_range.first_line == line_no
        end

        def to_normal_form(node, indentation)
          <<~RUBY.chomp
            #{node.keyword} #{node.condition.source}
            #{indentation}  #{node.body.source}
            #{indentation}end
          RUBY
        end

        def to_normal_form_with_heredoc(node, indentation, heredoc)
          heredoc_body, heredoc_end = heredoc

          <<~RUBY.chomp
            #{node.keyword} #{node.condition.source}
            #{indentation}  #{node.body.source}
            #{indentation}  #{heredoc_body.source.chomp}
            #{indentation}  #{heredoc_end.source.chomp}
            #{indentation}end
          RUBY
        end

        def to_modifier_form_with_move_comment(node, indentation, comment)
          <<~RUBY.chomp
            #{comment.source}
            #{indentation}#{node.body.source} #{node.keyword} #{node.condition.source}
          RUBY
        end

        def extract_heredoc_from(last_argument)
          heredoc_body = last_argument.loc.heredoc_body
          heredoc_end = last_argument.loc.heredoc_end

          [heredoc_body, heredoc_end]
        end

        def remove_heredoc(corrector, heredoc)
          heredoc.each do |range|
            corrector.remove(range_by_whole_lines(range, include_final_newline: true))
          end
        end

        def comment_on_node_line(node)
          processed_source.comments.find { |c| same_line?(c, node) }
        end

        def remove_comment(corrector, _node, comment)
          corrector.remove(range_with_surrounding_space(range: comment.source_range, side: :left))
        end
      end
    end
  end
end
