# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks if uses of quotes match the configured preference.
      #
      # @example EnforcedStyle: single_quotes (default)
      #   # bad
      #   "No special symbols"
      #   "No string interpolation"
      #   "Just text"
      #
      #   # good
      #   'No special symbols'
      #   'No string interpolation'
      #   'Just text'
      #   "Wait! What's #{this}!"
      #
      # @example EnforcedStyle: double_quotes
      #   # bad
      #   'Just some text'
      #   'No special chars or interpolation'
      #
      #   # good
      #   "Just some text"
      #   "No special chars or interpolation"
      #   "Every string in #{project} uses double_quotes"
      class StringLiterals < Base
        include ConfigurableEnforcedStyle
        include StringLiteralsHelp
        include StringHelp
        extend AutoCorrector

        MSG_INCONSISTENT = 'Inconsistent quote style.'

        def on_dstr(node)
          # Strings which are continued across multiple lines using \
          # are parsed as a `dstr` node with `str` children
          # If one part of that continued string contains interpolations,
          # then it will be parsed as a nested `dstr` node
          return unless consistent_multiline?
          return if node.heredoc?

          children = node.children
          return unless all_string_literals?(children)

          quote_styles = detect_quote_styles(node)

          if quote_styles.size > 1
            register_offense(node, message: MSG_INCONSISTENT)
          else
            check_multiline_quote_style(node, quote_styles[0])
          end

          ignore_node(node)
        end

        private

        def autocorrect(corrector, node)
          StringLiteralCorrector.correct(corrector, node, style)
        end

        def register_offense(node, message: nil)
          add_offense(node, message: message || message(node)) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def all_string_literals?(nodes)
          nodes.all? { |n| n.type?(:str, :dstr) }
        end

        def detect_quote_styles(node)
          styles = node.children.map { |c| c.loc.begin }

          # For multi-line strings that only have quote marks
          # at the beginning of the first line and the end of
          # the last, the begin and end region of each child
          # is nil. The quote marks are in the parent node.
          return [node.loc.begin.source] if styles.all?(&:nil?)

          styles.map(&:source).uniq
        end

        def message(_node)
          if style == :single_quotes
            "Prefer single-quoted strings when you don't need string " \
              'interpolation or special symbols.'
          else
            'Prefer double-quoted strings unless you need single quotes to ' \
              'avoid extra backslashes for escaping.'
          end
        end

        def offense?(node)
          wrong_quotes?(node) && !inside_interpolation?(node)
        end

        def consistent_multiline?
          cop_config['ConsistentQuotesInMultiline']
        end

        def check_multiline_quote_style(node, quote)
          children = node.children
          if unexpected_single_quotes?(quote)
            all_children_with_quotes = children.all? { |c| wrong_quotes?(c) }
            register_offense(node) if all_children_with_quotes
          elsif unexpected_double_quotes?(quote) && !accept_child_double_quotes?(children)
            register_offense(node)
          end
        end

        def unexpected_single_quotes?(quote)
          quote == "'" && style == :double_quotes
        end

        def unexpected_double_quotes?(quote)
          quote == '"' && style == :single_quotes
        end

        def accept_child_double_quotes?(nodes)
          nodes.any? { |n| n.dstr_type? || double_quotes_required?(n.source) }
        end
      end
    end
  end
end
