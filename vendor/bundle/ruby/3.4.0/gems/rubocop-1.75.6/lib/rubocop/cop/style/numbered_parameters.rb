# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for numbered parameters.
      #
      # It can either restrict the use of numbered parameters to
      # single-lined blocks, or disallow completely numbered parameters.
      #
      # @example EnforcedStyle: allow_single_line (default)
      #   # bad
      #   collection.each do
      #     puts _1
      #   end
      #
      #   # good
      #   collection.each { puts _1 }
      #
      # @example EnforcedStyle: disallow
      #   # bad
      #   collection.each { puts _1 }
      #
      #   # good
      #   collection.each { |item| puts item }
      #
      class NumberedParameters < Base
        include ConfigurableEnforcedStyle
        extend TargetRubyVersion

        MSG_DISALLOW = 'Avoid using numbered parameters.'
        MSG_MULTI_LINE = 'Avoid using numbered parameters for multi-line blocks.'

        minimum_target_ruby_version 2.7

        def on_numblock(node)
          if style == :disallow
            add_offense(node, message: MSG_DISALLOW)
          elsif node.multiline?
            add_offense(node, message: MSG_MULTI_LINE)
          end
        end
      end
    end
  end
end
