# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category conditional
  # @liquid_name case
  # @liquid_summary
  #   Renders a specific expression depending on the value of a specific variable.
  # @liquid_syntax
  #   {% case variable %}
  #     {% when first_value %}
  #       first_expression
  #     {% when second_value %}
  #       second_expression
  #     {% else %}
  #       third_expression
  #   {% endcase %}
  # @liquid_syntax_keyword variable The name of the variable you want to base your case statement on.
  # @liquid_syntax_keyword first_value A specific value to check for.
  # @liquid_syntax_keyword second_value A specific value to check for.
  # @liquid_syntax_keyword first_expression An expression to be rendered when the variable's value matches `first_value`.
  # @liquid_syntax_keyword second_expression An expression to be rendered when the variable's value matches `second_value`.
  # @liquid_syntax_keyword third_expression An expression to be rendered when the variable's value has no match.
  class Case < Block
    Syntax     = /(#{QuotedFragment})/o
    WhenSyntax = /(#{QuotedFragment})(?:(?:\s+or\s+|\s*\,\s*)(#{QuotedFragment}.*))?/om

    attr_reader :blocks, :left

    def initialize(tag_name, markup, options)
      super
      @blocks = []

      if markup =~ Syntax
        @left = parse_expression(Regexp.last_match(1))
      else
        raise SyntaxError, options[:locale].t("errors.syntax.case")
      end
    end

    def parse(tokens)
      body = case_body = new_body
      body = @blocks.last.attachment while parse_body(body, tokens)
      @blocks.reverse_each do |condition|
        body = condition.attachment
        unless body.frozen?
          body.remove_blank_strings if blank?
          body.freeze
        end
      end
      case_body.freeze
    end

    def nodelist
      @blocks.map(&:attachment)
    end

    def unknown_tag(tag, markup, tokens)
      case tag
      when 'when'
        record_when_condition(markup)
      when 'else'
        record_else_condition(markup)
      else
        super
      end
    end

    def render_to_output_buffer(context, output)
      execute_else_block = true

      @blocks.each do |block|
        if block.else?
          block.attachment.render_to_output_buffer(context, output) if execute_else_block
          next
        end

        result = Liquid::Utils.to_liquid_value(
          block.evaluate(context)
        )

        if result
          execute_else_block = false
          block.attachment.render_to_output_buffer(context, output)
        end
      end

      output
    end

    private

    def record_when_condition(markup)
      body = new_body

      while markup
        unless markup =~ WhenSyntax
          raise SyntaxError, options[:locale].t("errors.syntax.case_invalid_when")
        end

        markup = Regexp.last_match(2)

        block = Condition.new(@left, '==', Condition.parse_expression(parse_context, Regexp.last_match(1)))
        block.attach(body)
        @blocks << block
      end
    end

    def record_else_condition(markup)
      unless markup.strip.empty?
        raise SyntaxError, options[:locale].t("errors.syntax.case_invalid_else")
      end

      block = ElseCondition.new
      block.attach(new_body)
      @blocks << block
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        [@node.left] + @node.blocks
      end
    end
  end

  Template.register_tag('case', Case)
end
