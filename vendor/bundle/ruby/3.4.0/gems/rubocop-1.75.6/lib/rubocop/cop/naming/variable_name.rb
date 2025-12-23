# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks that the configured style (snake_case or camelCase) is used for all variable names.
      # This includes local variables, instance variables, class variables, method arguments
      # (positional, keyword, rest or block), and block arguments.
      #
      # The cop can also be configured to forbid using specific names for variables, using
      # `ForbiddenIdentifiers` or `ForbiddenPatterns`. In addition to the above, this applies
      # to global variables as well.
      #
      # Method definitions and method calls are not affected by this cop.
      #
      # @example EnforcedStyle: snake_case (default)
      #   # bad
      #   fooBar = 1
      #
      #   # good
      #   foo_bar = 1
      #
      # @example EnforcedStyle: camelCase
      #   # bad
      #   foo_bar = 1
      #
      #   # good
      #   fooBar = 1
      #
      # @example AllowedIdentifiers: ['fooBar']
      #   # good (with EnforcedStyle: snake_case)
      #   fooBar = 1
      #
      # @example AllowedPatterns: ['_v\d+\z']
      #   # good (with EnforcedStyle: camelCase)
      #   release_v1 = true
      #
      # @example ForbiddenIdentifiers: ['fooBar']
      #   # bad (in all cases)
      #   fooBar = 1
      #   @fooBar = 1
      #   @@fooBar = 1
      #   $fooBar = 1
      #
      # @example ForbiddenPatterns: ['_v\d+\z']
      #   # bad (in all cases)
      #   release_v1 = true
      #   @release_v1 = true
      #   @@release_v1 = true
      #   $release_v1 = true
      #
      class VariableName < Base
        include AllowedIdentifiers
        include ConfigurableNaming
        include AllowedPattern
        include ForbiddenIdentifiers
        include ForbiddenPattern

        MSG = 'Use %<style>s for variable names.'
        MSG_FORBIDDEN = '`%<identifier>s` is forbidden, use another name instead.'

        def valid_name?(node, name, given_style = style)
          super || matches_allowed_pattern?(name)
        end

        def on_lvasgn(node)
          return unless (name = node.name)
          return if allowed_identifier?(name)

          if forbidden_name?(name)
            register_forbidden_name(node)
          else
            check_name(node, name, node.loc.name)
          end
        end
        alias on_ivasgn    on_lvasgn
        alias on_cvasgn    on_lvasgn
        alias on_arg       on_lvasgn
        alias on_optarg    on_lvasgn
        alias on_restarg   on_lvasgn
        alias on_kwoptarg  on_lvasgn
        alias on_kwarg     on_lvasgn
        alias on_kwrestarg on_lvasgn
        alias on_blockarg  on_lvasgn
        alias on_lvar      on_lvasgn

        # Only forbidden names are checked for global variable assignment
        def on_gvasgn(node)
          return unless (name = node.name)
          return unless forbidden_name?(name)

          register_forbidden_name(node)
        end

        private

        def forbidden_name?(name)
          forbidden_identifier?(name) || forbidden_pattern?(name)
        end

        def message(style)
          format(MSG, style: style)
        end

        def register_forbidden_name(node)
          message = format(MSG_FORBIDDEN, identifier: node.name)
          add_offense(node.loc.name, message: message)
        end
      end
    end
  end
end
