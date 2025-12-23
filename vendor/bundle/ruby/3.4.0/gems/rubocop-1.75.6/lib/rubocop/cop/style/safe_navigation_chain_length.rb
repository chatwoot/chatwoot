# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces safe navigation chains length to not exceed the configured maximum.
      # The longer the chain is, the harder it becomes to track what on it could be
      # returning `nil`.
      #
      # There is a potential interplay with `Style/SafeNavigation` - if both are enabled
      # and their settings are "incompatible", one of the cops will complain about what
      # the other proposes.
      #
      # E.g. if `Style/SafeNavigation` is configured with `MaxChainLength: 2` (default)
      # and this cop is configured with `Max: 1`, then for `foo.bar.baz if foo` the former
      # will suggest `foo&.bar&.baz`, which is an offense for the latter.
      #
      # @example Max: 2 (default)
      #   # bad
      #   user&.address&.zip&.upcase
      #
      #   # good
      #   user&.address&.zip
      #   user.address.zip if user
      #
      class SafeNavigationChainLength < Base
        MSG = 'Avoid safe navigation chains longer than %<max>d calls.'

        def on_csend(node)
          safe_navigation_chains = safe_navigation_chains(node)
          return if safe_navigation_chains.size < max

          add_offense(safe_navigation_chains.last, message: format(MSG, max: max))
        end

        private

        def safe_navigation_chains(node)
          node.each_ancestor.with_object([]) do |parent, chains|
            break chains unless parent.csend_type?

            chains << parent
          end
        end

        def max
          cop_config['Max'] || 2
        end
      end
    end
  end
end
