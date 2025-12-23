# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of consistent method names
      # from the `String` class.
      #
      # @example
      #   # bad
      #   'name'.intern
      #   'var'.unfavored_method
      #
      #   # good
      #   'name'.to_sym
      #   'var'.preferred_method
      class StringMethods < Base
        include MethodPreference
        extend AutoCorrector

        MSG = 'Prefer `%<prefer>s` over `%<current>s`.'

        def on_send(node)
          return unless (preferred_method = preferred_method(node.method_name))

          message = format(MSG, prefer: preferred_method, current: node.method_name)

          add_offense(node.loc.selector, message: message) do |corrector|
            corrector.replace(node.loc.selector, preferred_method(node.method_name))
          end
        end
        alias on_csend on_send
      end
    end
  end
end
