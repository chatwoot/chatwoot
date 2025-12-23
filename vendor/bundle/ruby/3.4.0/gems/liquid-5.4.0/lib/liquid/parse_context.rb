# frozen_string_literal: true

module Liquid
  class ParseContext
    attr_accessor :locale, :line_number, :trim_whitespace, :depth
    attr_reader :partial, :warnings, :error_mode

    def initialize(options = {})
      @template_options = options ? options.dup : {}

      @locale   = @template_options[:locale] ||= I18n.new
      @warnings = []

      self.depth   = 0
      self.partial = false
    end

    def [](option_key)
      @options[option_key]
    end

    def new_block_body
      Liquid::BlockBody.new
    end

    def new_tokenizer(markup, start_line_number: nil, for_liquid_tag: false)
      Tokenizer.new(markup, line_number: start_line_number, for_liquid_tag: for_liquid_tag)
    end

    def parse_expression(markup)
      Expression.parse(markup)
    end

    def partial=(value)
      @partial = value
      @options = value ? partial_options : @template_options

      @error_mode = @options[:error_mode] || Template.error_mode
    end

    def partial_options
      @partial_options ||= begin
        dont_pass = @template_options[:include_options_blacklist]
        if dont_pass == true
          { locale: locale }
        elsif dont_pass.is_a?(Array)
          @template_options.reject { |k, _v| dont_pass.include?(k) }
        else
          @template_options
        end
      end
    end
  end
end
