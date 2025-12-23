# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies places where `render text:` can be
      # replaced with `render plain:`.
      #
      # @example
      #   # bad - explicit MIME type to `text/plain`
      #   render text: 'Ruby!', content_type: 'text/plain'
      #
      #   # good - short and precise
      #   render plain: 'Ruby!'
      #
      #   # good - explicit MIME type not to `text/plain`
      #   render text: 'Ruby!', content_type: 'text/html'
      #
      # @example ContentTypeCompatibility: true (default)
      #   # good - sets MIME type to `text/html`
      #   render text: 'Ruby!'
      #
      # @example ContentTypeCompatibility: false
      #   # bad - sets MIME type to `text/html`
      #   render text: 'Ruby!'
      #
      class RenderPlainText < Base
        extend AutoCorrector

        MSG = 'Prefer `render plain:` over `render text:`.'
        RESTRICT_ON_SEND = %i[render].freeze

        def_node_matcher :render_plain_text?, <<~PATTERN
          (send nil? :render $(hash <$(pair (sym :text) $_) ...>))
        PATTERN

        def on_send(node)
          render_plain_text?(node) do |options_node, option_node, option_value|
            content_type_node = find_content_type(options_node)
            return unless compatible_content_type?(content_type_node)

            add_offense(node) do |corrector|
              rest_options = options_node.pairs - [option_node, content_type_node].compact

              corrector.replace(node, replacement(rest_options, option_value))
            end
          end
        end

        private

        def find_content_type(node)
          node.pairs.find { |p| p.key.value.to_sym == :content_type }
        end

        def compatible_content_type?(pair_node)
          if pair_node.nil?
            !cop_config['ContentTypeCompatibility']
          elsif pair_node.value.respond_to?(:value)
            pair_node.value.value == 'text/plain'
          end
        end

        def replacement(rest_options, option_value)
          if rest_options.any?
            "render plain: #{option_value.source}, #{rest_options.map(&:source).join(', ')}"
          else
            "render plain: #{option_value.source}"
          end
        end
      end
    end
  end
end
