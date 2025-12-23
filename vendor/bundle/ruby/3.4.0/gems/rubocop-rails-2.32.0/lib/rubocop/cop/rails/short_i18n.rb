# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces that short forms of `I18n` methods are used:
      # `t` instead of `translate` and `l` instead of `localize`.
      #
      # This cop has two different enforcement modes. When the EnforcedStyle
      # is conservative (the default) then only `I18n.translate` and `I18n.localize`
      # calls are added as offenses.
      #
      # When the EnforcedStyle is aggressive then all `translate` and `localize` calls
      # without a receiver are added as offenses.
      #
      # @example
      #   # bad
      #   I18n.translate :key
      #   I18n.localize Time.now
      #
      #   # good
      #   I18n.t :key
      #   I18n.l Time.now
      #
      # @example EnforcedStyle: conservative (default)
      #   # good
      #   translate :key
      #   localize Time.now
      #   t :key
      #   l Time.now
      #
      # @example EnforcedStyle: aggressive
      #   # bad
      #   translate :key
      #   localize Time.now
      #
      #   # good
      #   t :key
      #   l Time.now
      #
      class ShortI18n < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Use `%<good_method>s` instead of `%<bad_method>s`.'

        PREFERRED_METHODS = { translate: :t, localize: :l }.freeze

        RESTRICT_ON_SEND = PREFERRED_METHODS.keys.freeze

        def_node_matcher :long_i18n?, <<~PATTERN
          (send {nil? (const {nil? cbase} :I18n)} ${:translate :localize} ...)
        PATTERN

        def on_send(node)
          return if style == :conservative && !node.receiver

          long_i18n?(node) do |method_name|
            good_method = PREFERRED_METHODS[method_name]
            message = format(MSG, good_method: good_method, bad_method: method_name)
            range = node.loc.selector

            add_offense(range, message: message) do |corrector|
              corrector.replace(range, PREFERRED_METHODS[method_name])
            end
          end
        end
      end
    end
  end
end
