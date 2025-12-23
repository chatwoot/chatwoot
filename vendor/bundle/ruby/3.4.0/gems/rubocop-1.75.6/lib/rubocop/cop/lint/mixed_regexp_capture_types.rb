# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Do not mix named captures and numbered captures in a `Regexp` literal
      # because numbered capture is ignored if they're mixed.
      # Replace numbered captures with non-capturing groupings or
      # named captures.
      #
      # @example
      #   # bad
      #   /(?<foo>FOO)(BAR)/
      #
      #   # good
      #   /(?<foo>FOO)(?<bar>BAR)/
      #
      #   # good
      #   /(?<foo>FOO)(?:BAR)/
      #
      #   # good
      #   /(FOO)(BAR)/
      #
      class MixedRegexpCaptureTypes < Base
        MSG = 'Do not mix named captures and numbered captures in a Regexp literal.'

        def on_regexp(node)
          return if node.interpolation?
          return if node.each_capture(named: false).none?
          return if node.each_capture(named: true).none?

          add_offense(node)
        end
      end
    end
  end
end
