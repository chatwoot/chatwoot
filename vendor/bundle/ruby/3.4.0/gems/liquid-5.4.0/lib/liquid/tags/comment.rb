# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category syntax
  # @liquid_name comment
  # @liquid_summary
  #   Prevents an expression from being rendered or output.
  # @liquid_description
  #   Any text inside `comment` tags won't be output, and any Liquid code won't be rendered.
  # @liquid_syntax
  #   {% comment %}
  #     content
  #   {% endcomment %}
  # @liquid_syntax_keyword content The content of the comment.
  class Comment < Block
    def render_to_output_buffer(_context, output)
      output
    end

    def unknown_tag(_tag, _markup, _tokens)
    end

    def blank?
      true
    end
  end

  Template.register_tag('comment', Comment)
end
