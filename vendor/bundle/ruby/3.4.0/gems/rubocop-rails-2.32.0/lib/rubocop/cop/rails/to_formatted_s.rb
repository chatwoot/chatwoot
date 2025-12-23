# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for consistent uses of `to_fs` or `to_formatted_s`,
      # depending on the cop's configuration.
      #
      # @example EnforcedStyle: to_fs (default)
      #
      #   # bad
      #   time.to_formatted_s(:db)
      #
      #   # good
      #   time.to_fs(:db)
      #
      # @example EnforcedStyle: to_formatted_s
      #
      #   # bad
      #   time.to_fs(:db)
      #
      #   # good
      #   time.to_formatted_s(:db)
      #
      class ToFormattedS < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 7.0

        MSG = 'Use `%<prefer>s` instead.'
        RESTRICT_ON_SEND = %i[to_formatted_s to_fs].freeze

        def on_send(node)
          return if node.method?(style)

          add_offense(node.loc.selector, message: format(MSG, prefer: style)) do |corrector|
            corrector.replace(node.loc.selector, style)
          end
        end
        alias on_csend on_send
      end
    end
  end
end
