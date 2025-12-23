# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the formatting of empty method definitions.
      # By default it enforces empty method definitions to go on a single
      # line (compact style), but it can be configured to enforce the `end`
      # to go on its own line (expanded style).
      #
      # NOTE: A method definition is not considered empty if it contains
      # comments.
      #
      # NOTE: Autocorrection will not be applied for the `compact` style
      # if the resulting code is longer than the `Max` configuration for
      # `Layout/LineLength`, but an offense will still be registered.
      #
      # @example EnforcedStyle: compact (default)
      #   # bad
      #   def foo(bar)
      #   end
      #
      #   def self.foo(bar)
      #   end
      #
      #   # good
      #   def foo(bar); end
      #
      #   def foo(bar)
      #     # baz
      #   end
      #
      #   def self.foo(bar); end
      #
      # @example EnforcedStyle: expanded
      #   # bad
      #   def foo(bar); end
      #
      #   def self.foo(bar); end
      #
      #   # good
      #   def foo(bar)
      #   end
      #
      #   def self.foo(bar)
      #   end
      class EmptyMethod < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG_COMPACT = 'Put empty method definitions on a single line.'
        MSG_EXPANDED = 'Put the `end` of empty method definitions on the next line.'

        def on_def(node)
          return if node.body || processed_source.contains_comment?(node.source_range)
          return if correct_style?(node)

          add_offense(node) do |corrector|
            correction = corrected(node)
            next if compact_style? && max_line_length && correction.size > max_line_length

            corrector.replace(node, correction)
          end
        end
        alias on_defs on_def

        private

        def message(_range)
          compact_style? ? MSG_COMPACT : MSG_EXPANDED
        end

        def correct_style?(node)
          (compact_style? && compact?(node)) || (expanded_style? && expanded?(node))
        end

        def corrected(node)
          scope = node.receiver ? "#{node.receiver.source}." : ''
          arguments = if node.arguments?
                        args = node.arguments.map(&:source).join(', ')

                        parentheses?(node.arguments) ? "(#{args})" : " #{args}"
                      end
          signature = [scope, node.method_name, arguments].join

          ["def #{signature}", 'end'].join(joint(node))
        end

        def joint(node)
          indent = ' ' * node.loc.column

          compact_style? ? '; ' : "\n#{indent}"
        end

        def compact?(node)
          node.single_line?
        end

        def expanded?(node)
          node.multiline?
        end

        def compact_style?
          style == :compact
        end

        def expanded_style?
          style == :expanded
        end

        def max_line_length
          return unless config.cop_enabled?('Layout/LineLength')

          config.for_cop('Layout/LineLength')['Max']
        end
      end
    end
  end
end
