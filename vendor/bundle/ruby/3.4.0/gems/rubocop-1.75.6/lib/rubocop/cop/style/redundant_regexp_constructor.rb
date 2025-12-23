# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the instantiation of regexp using redundant `Regexp.new` or `Regexp.compile`.
      # Autocorrect replaces to regexp literal which is the simplest and fastest.
      #
      # @example
      #
      #   # bad
      #   Regexp.new(/regexp/)
      #   Regexp.compile(/regexp/)
      #
      #   # good
      #   /regexp/
      #   Regexp.new('regexp')
      #   Regexp.compile('regexp')
      #
      class RedundantRegexpConstructor < Base
        extend AutoCorrector

        MSG = 'Remove the redundant `Regexp.%<method>s`.'
        RESTRICT_ON_SEND = %i[new compile].freeze

        # @!method redundant_regexp_constructor(node)
        def_node_matcher :redundant_regexp_constructor, <<~PATTERN
          (send
            (const {nil? cbase} :Regexp) {:new :compile}
            (regexp $... (regopt $...)))
        PATTERN

        def on_send(node)
          return unless (regexp, regopt = redundant_regexp_constructor(node))

          add_offense(node, message: format(MSG, method: node.method_name)) do |corrector|
            pattern = regexp.map(&:source).join
            regopt = regopt.join

            corrector.replace(node, "/#{pattern}/#{regopt}")
          end
        end
      end
    end
  end
end
