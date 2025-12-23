# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `URI::Parser.new` can be replaced by `URI::DEFAULT_PARSER`.
      #
      # @example
      #   # bad
      #   URI::Parser.new
      #
      #   # good
      #   URI::DEFAULT_PARSER
      #
      class UriDefaultParser < Base
        extend AutoCorrector

        MSG = 'Use `%<double_colon>sURI::DEFAULT_PARSER` instead of `%<double_colon>sURI::Parser.new`.'
        RESTRICT_ON_SEND = %i[new].freeze

        def_node_matcher :uri_parser_new?, <<~PATTERN
          (send
            (const
              (const ${nil? cbase} :URI) :Parser) :new)
        PATTERN

        def on_send(node)
          uri_parser_new?(node) do |captured_value|
            double_colon = captured_value ? '::' : ''
            message = format(MSG, double_colon: double_colon)

            add_offense(node, message: message) do |corrector|
              corrector.replace(node, "#{double_colon}URI::DEFAULT_PARSER")
            end
          end
        end
      end
    end
  end
end
