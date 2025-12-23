# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of methods `Hash#has_key?` and
      # `Hash#has_value?`, and suggests using `Hash#key?` and `Hash#value?` instead.
      #
      # It is configurable to enforce the verbose method names, by using the
      # `EnforcedStyle: verbose` configuration.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   is a `Hash` or responds to the replacement methods.
      #
      # @example EnforcedStyle: short (default)
      #  # bad
      #  Hash#has_key?
      #  Hash#has_value?
      #
      #  # good
      #  Hash#key?
      #  Hash#value?
      #
      # @example EnforcedStyle: verbose
      #  # bad
      #  Hash#key?
      #  Hash#value?
      #
      #  # good
      #  Hash#has_key?
      #  Hash#has_value?
      class PreferredHashMethods < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Use `Hash#%<prefer>s` instead of `Hash#%<current>s`.'

        OFFENDING_SELECTORS = { short: %i[has_key? has_value?], verbose: %i[key? value?] }.freeze

        RESTRICT_ON_SEND = OFFENDING_SELECTORS.values.flatten.freeze

        def on_send(node)
          return unless node.arguments.one? && offending_selector?(node.method_name)

          message = message(node.method_name)

          add_offense(node.loc.selector, message: message) do |corrector|
            corrector.replace(node.loc.selector, proper_method_name(node.loc.selector.source))
          end
        end
        alias on_csend on_send

        private

        def message(method_name)
          format(MSG, prefer: proper_method_name(method_name), current: method_name)
        end

        def proper_method_name(method_name)
          if style == :verbose
            "has_#{method_name}"
          else
            method_name.to_s.delete_prefix('has_')
          end
        end

        def offending_selector?(method_name)
          OFFENDING_SELECTORS[style].include?(method_name)
        end
      end
    end
  end
end
