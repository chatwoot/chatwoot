# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for endless methods.
      #
      # It can enforce endless method definitions whenever possible or with single line methods.
      # It can also disallow multiline endless method definitions or all endless definitions.
      #
      # `require_single_line` style enforces endless method definitions for single line methods.
      # `require_always` style enforces endless method definitions for single statement methods.
      #
      # Other method definition types are not considered by this cop.
      #
      # The supported styles are:
      #
      # * allow_single_line (default) - only single line endless method definitions are allowed.
      # * allow_always - all endless method definitions are allowed.
      # * disallow - all endless method definitions are disallowed.
      # * require_single_line - endless method definitions are required for single line methods.
      # * require_always - all endless method definitions are required.
      #
      # NOTE: Incorrect endless method definitions will always be
      # corrected to a multi-line definition.
      #
      # @example EnforcedStyle: allow_single_line (default)
      #   # bad, multi-line endless method
      #   def my_method = x.foo
      #                    .bar
      #                    .baz
      #
      #   # good
      #   def my_method
      #     x
      #   end
      #
      #   # good
      #   def my_method = x
      #
      #   # good
      #   def my_method
      #     x.foo
      #      .bar
      #      .baz
      #   end
      #
      # @example EnforcedStyle: allow_always
      #   # good
      #   def my_method
      #     x
      #   end
      #
      #   # good
      #   def my_method = x
      #
      #   # good
      #   def my_method = x.foo
      #                    .bar
      #                    .baz
      #
      #   # good
      #   def my_method
      #     x.foo
      #      .bar
      #      .baz
      #   end
      #
      # @example EnforcedStyle: disallow
      #   # bad
      #   def my_method = x
      #
      #   # bad
      #   def my_method = x.foo
      #                    .bar
      #                    .baz
      #
      #   # good
      #   def my_method
      #     x
      #   end
      #
      #   # good
      #   def my_method
      #     x.foo
      #      .bar
      #      .baz
      #   end
      #
      # @example EnforcedStyle: require_single_line
      #   # bad
      #   def my_method
      #     x
      #   end
      #
      #   # bad
      #   def my_method = x.foo
      #                    .bar
      #                    .baz
      #
      #   # good
      #   def my_method = x
      #
      #   # good
      #   def my_method
      #     x.foo
      #      .bar
      #      .baz
      #   end
      #
      # @example EnforcedStyle: require_always
      #   # bad
      #   def my_method
      #     x
      #   end
      #
      #   # bad
      #   def my_method
      #     x.foo
      #      .bar
      #      .baz
      #   end
      #
      #   # good
      #   def my_method = x
      #
      #   # good
      #   def my_method = x.foo
      #                    .bar
      #                    .baz
      #
      class EndlessMethod < Base
        include ConfigurableEnforcedStyle
        include EndlessMethodRewriter
        extend TargetRubyVersion
        extend AutoCorrector

        minimum_target_ruby_version 3.0

        CORRECTION_STYLES = %w[multiline single_line].freeze
        MSG = 'Avoid endless method definitions.'
        MSG_MULTI_LINE = 'Avoid endless method definitions with multiple lines.'
        MSG_REQUIRE_SINGLE = 'Use endless method definitions for single line methods.'
        MSG_REQUIRE_ALWAYS = 'Use endless method definitions.'

        def on_def(node)
          return if node.assignment_method?

          case style
          when :allow_single_line, :allow_always
            handle_allow_style(node)
          when :disallow
            handle_disallow_style(node)
          when :require_single_line
            handle_require_single_line_style(node)
          when :require_always
            handle_require_always_style(node)
          end
        end

        private

        def handle_allow_style(node)
          return unless node.endless?
          return if node.single_line? || style == :allow_always

          add_offense(node, message: MSG_MULTI_LINE) do |corrector|
            correct_to_multiline(corrector, node)
          end
        end

        def handle_require_single_line_style(node)
          if node.endless? && !node.single_line?
            add_offense(node, message: MSG_MULTI_LINE) do |corrector|
              correct_to_multiline(corrector, node)
            end
          elsif !node.endless? && can_be_made_endless?(node) && node.body.single_line?
            return if too_long_when_made_endless?(node)

            add_offense(node, message: MSG_REQUIRE_SINGLE) do |corrector|
              corrector.replace(node, endless_replacement(node))
            end
          end
        end

        def handle_require_always_style(node)
          return if node.endless? || !can_be_made_endless?(node)
          return if too_long_when_made_endless?(node)

          add_offense(node, message: MSG_REQUIRE_ALWAYS) do |corrector|
            corrector.replace(node, endless_replacement(node))
          end
        end

        def handle_disallow_style(node)
          return unless node.endless?

          add_offense(node) { |corrector| correct_to_multiline(corrector, node) }
        end

        def correct_to_multiline(corrector, node)
          replacement = <<~RUBY.strip
            def #{node.method_name}#{arguments(node)}
              #{node.body.source}
            end
          RUBY

          corrector.replace(node, replacement)
        end

        def endless_replacement(node)
          <<~RUBY.strip
            def #{node.method_name}#{arguments(node)} = #{node.body.source}
          RUBY
        end

        def arguments(node, missing = '')
          node.arguments.any? ? node.arguments.source : missing
        end

        def can_be_made_endless?(node)
          node.body && !node.body.begin_type? && !node.body.kwbegin_type?
        end

        def too_long_when_made_endless?(node)
          return false unless config.cop_enabled?('Layout/LineLength')

          endless_replacement(node).length > config.for_cop('Layout/LineLength')['Max']
        end
      end
    end
  end
end
