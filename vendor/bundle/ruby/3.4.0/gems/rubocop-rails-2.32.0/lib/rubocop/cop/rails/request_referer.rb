# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for consistent uses of `request.referer` or
      # `request.referrer`, depending on the cop's configuration.
      #
      # @example EnforcedStyle: referer (default)
      #   # bad
      #   request.referrer
      #
      #   # good
      #   request.referer
      #
      # @example EnforcedStyle: referrer
      #   # bad
      #   request.referer
      #
      #   # good
      #   request.referrer
      class RequestReferer < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Use `request.%<prefer>s` instead of `request.%<current>s`.'
        RESTRICT_ON_SEND = %i[referer referrer].freeze

        def_node_matcher :referer?, <<~PATTERN
          (send (send nil? :request) {:referer :referrer})
        PATTERN

        def on_send(node)
          referer?(node) do
            return unless node.method?(wrong_method_name)

            add_offense(node) do |corrector|
              corrector.replace(node, "request.#{style}")
            end
          end
        end

        private

        def message(_range)
          format(MSG, prefer: style, current: wrong_method_name)
        end

        def wrong_method_name
          style == :referer ? :referrer : :referer
        end
      end
    end
  end
end
