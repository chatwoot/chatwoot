# frozen_string_literal: true

module Liquid
  module ParserSwitching
    def strict_parse_with_error_mode_fallback(markup)
      strict_parse_with_error_context(markup)
    rescue SyntaxError => e
      case parse_context.error_mode
      when :strict
        raise
      when :warn
        parse_context.warnings << e
      end
      lax_parse(markup)
    end

    def parse_with_selected_parser(markup)
      case parse_context.error_mode
      when :strict then strict_parse_with_error_context(markup)
      when :lax    then lax_parse(markup)
      when :warn
        begin
          strict_parse_with_error_context(markup)
        rescue SyntaxError => e
          parse_context.warnings << e
          lax_parse(markup)
        end
      end
    end

    private

    def strict_parse_with_error_context(markup)
      strict_parse(markup)
    rescue SyntaxError => e
      e.line_number    = line_number
      e.markup_context = markup_context(markup)
      raise e
    end

    def markup_context(markup)
      "in \"#{markup.strip}\""
    end
  end
end
