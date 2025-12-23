# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the use of `I18n.locale=` method.
      #
      # The `locale` attribute persists for the rest of the Ruby runtime, potentially causing
      # unexpected behavior at a later time.
      # Using `I18n.with_locale` ensures the code passed in the block is the only place `I18n.locale` is affected.
      # It eliminates the possibility of a `locale` sticking around longer than intended.
      #
      # @example
      #   # bad
      #   I18n.locale = :fr
      #
      #   # good
      #   I18n.with_locale(:fr) do
      #   end
      #
      class I18nLocaleAssignment < Base
        MSG = 'Use `I18n.with_locale` with block instead of `I18n.locale=`.'
        RESTRICT_ON_SEND = %i[locale=].freeze

        def_node_matcher :i18n_locale_assignment?, <<~PATTERN
          (send (const {nil? cbase} :I18n) :locale= ...)
        PATTERN

        def on_send(node)
          return unless i18n_locale_assignment?(node)

          add_offense(node)
        end
      end
    end
  end
end
