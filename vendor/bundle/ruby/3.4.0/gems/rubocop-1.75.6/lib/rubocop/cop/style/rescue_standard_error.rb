# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for rescuing `StandardError`. There are two supported
      # styles `implicit` and `explicit`. This cop will not register an offense
      # if any error other than `StandardError` is specified.
      #
      # @example EnforcedStyle: explicit (default)
      #   # `explicit` will enforce using `rescue StandardError`
      #   # instead of `rescue`.
      #
      #   # bad
      #   begin
      #     foo
      #   rescue
      #     bar
      #   end
      #
      #   # good
      #   begin
      #     foo
      #   rescue StandardError
      #     bar
      #   end
      #
      #   # good
      #   begin
      #     foo
      #   rescue OtherError
      #     bar
      #   end
      #
      #   # good
      #   begin
      #     foo
      #   rescue StandardError, SecurityError
      #     bar
      #   end
      #
      # @example EnforcedStyle: implicit
      #   # `implicit` will enforce using `rescue` instead of
      #   # `rescue StandardError`.
      #
      #   # bad
      #   begin
      #     foo
      #   rescue StandardError
      #     bar
      #   end
      #
      #   # good
      #   begin
      #     foo
      #   rescue
      #     bar
      #   end
      #
      #   # good
      #   begin
      #     foo
      #   rescue OtherError
      #     bar
      #   end
      #
      #   # good
      #   begin
      #     foo
      #   rescue StandardError, SecurityError
      #     bar
      #   end
      class RescueStandardError < Base
        include RescueNode
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG_IMPLICIT = 'Omit the error class when rescuing `StandardError` by itself.'
        MSG_EXPLICIT = 'Avoid rescuing without specifying an error class.'

        # @!method rescue_without_error_class?(node)
        def_node_matcher :rescue_without_error_class?, <<~PATTERN
          (resbody nil? _ _)
        PATTERN

        # @!method rescue_standard_error?(node)
        def_node_matcher :rescue_standard_error?, <<~PATTERN
          (resbody $(array (const {nil? cbase} :StandardError)) _ _)
        PATTERN

        def on_resbody(node)
          return if rescue_modifier?(node)

          case style
          when :implicit
            rescue_standard_error?(node) do |error|
              offense_for_implicit_enforced_style(node, error)
            end
          when :explicit
            rescue_without_error_class?(node) { offense_for_explicit_enforced_style(node) }
          end
        end

        private

        def offense_for_implicit_enforced_style(node, error)
          range = node.loc.keyword.join(error.source_range)

          add_offense(range, message: MSG_IMPLICIT) do |corrector|
            error = rescue_standard_error?(node)
            range = range_between(node.loc.keyword.end_pos, error.source_range.end_pos)

            corrector.remove(range)
          end
        end

        def offense_for_explicit_enforced_style(node)
          add_offense(node.loc.keyword, message: MSG_EXPLICIT) do |corrector|
            corrector.insert_after(node.loc.keyword, ' StandardError')
          end
        end
      end
    end
  end
end
