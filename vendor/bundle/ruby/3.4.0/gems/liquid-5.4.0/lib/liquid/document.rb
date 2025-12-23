# frozen_string_literal: true

module Liquid
  class Document
    def self.parse(tokens, parse_context)
      doc = new(parse_context)
      doc.parse(tokens, parse_context)
      doc
    end

    attr_reader :parse_context, :body

    def initialize(parse_context)
      @parse_context = parse_context
      @body = new_body
    end

    def nodelist
      @body.nodelist
    end

    def parse(tokenizer, parse_context)
      while parse_body(tokenizer)
      end
      @body.freeze
    rescue SyntaxError => e
      e.line_number ||= parse_context.line_number
      raise
    end

    def unknown_tag(tag, _markup, _tokenizer)
      case tag
      when 'else', 'end'
        raise SyntaxError, parse_context.locale.t("errors.syntax.unexpected_outer_tag", tag: tag)
      else
        raise SyntaxError, parse_context.locale.t("errors.syntax.unknown_tag", tag: tag)
      end
    end

    def render_to_output_buffer(context, output)
      @body.render_to_output_buffer(context, output)
    end

    def render(context)
      render_to_output_buffer(context, +'')
    end

    private

    def new_body
      parse_context.new_block_body
    end

    def parse_body(tokenizer)
      @body.parse(tokenizer, parse_context) do |unknown_tag_name, unknown_tag_markup|
        if unknown_tag_name
          unknown_tag(unknown_tag_name, unknown_tag_markup, tokenizer)
          true
        else
          false
        end
      end
    end
  end
end
