# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Prefer `response.parsed_body` to custom parsing logic for `response.body`.
      #
      # @safety
      #   This cop is unsafe because Content-Type may not be `application/json` or `text/html`.
      #   For example, the proprietary Content-Type provided by corporate entities such as
      #   `application/vnd.github+json` is not supported at `response.parsed_body` by default,
      #   so you still have to use `JSON.parse(response.body)` there.
      #
      # @example
      #   # bad
      #   JSON.parse(response.body)
      #
      #   # bad
      #   Nokogiri::HTML.parse(response.body)
      #
      #   # bad
      #   Nokogiri::HTML5.parse(response.body)
      #
      #   # good
      #   response.parsed_body
      class ResponseParsedBody < Base
        extend AutoCorrector
        extend TargetRailsVersion

        RESTRICT_ON_SEND = %i[parse].freeze

        minimum_target_rails_version 5.0

        # @!method json_parse_response_body?(node)
        def_node_matcher :json_parse_response_body?, <<~PATTERN
          (send
            (const {nil? cbase} :JSON)
            :parse
            (send
              (send nil? :response)
              :body
            )
          )
        PATTERN

        # @!method nokogiri_html_parse_response_body(node)
        def_node_matcher :nokogiri_html_parse_response_body, <<~PATTERN
          (send
            (const
              (const {nil? cbase} :Nokogiri)
              ${:HTML :HTML5}
            )
            :parse
            (send
              (send nil? :response)
              :body
            )
          )
        PATTERN

        def on_send(node)
          check_json_parse_response_body(node)

          return unless target_rails_version >= 7.1

          check_nokogiri_html_parse_response_body(node)
        end

        private

        def autocorrect(corrector, node)
          corrector.replace(node, 'response.parsed_body')
        end

        def check_json_parse_response_body(node)
          return unless json_parse_response_body?(node)

          add_offense(
            node,
            message: 'Prefer `response.parsed_body` to `JSON.parse(response.body)`.'
          ) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def check_nokogiri_html_parse_response_body(node)
          return unless (const = nokogiri_html_parse_response_body(node))

          add_offense(
            node,
            message: "Prefer `response.parsed_body` to `Nokogiri::#{const}.parse(response.body)`."
          ) do |corrector|
            autocorrect(corrector, node)
          end
        end
      end
    end
  end
end
