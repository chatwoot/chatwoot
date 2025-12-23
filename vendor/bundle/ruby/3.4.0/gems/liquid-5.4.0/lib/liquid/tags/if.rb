# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category conditional
  # @liquid_name if
  # @liquid_summary
  #   Renders an expression if a specific condition is `true`.
  # @liquid_syntax
  #   {% if condition %}
  #     expression
  #   {% endif %}
  # @liquid_syntax_keyword condition The condition to evaluate.
  # @liquid_syntax_keyword expression The expression to render if the condition is met.
  class If < Block
    Syntax                  = /(#{QuotedFragment})\s*([=!<>a-z_]+)?\s*(#{QuotedFragment})?/o
    ExpressionsAndOperators = /(?:\b(?:\s?and\s?|\s?or\s?)\b|(?:\s*(?!\b(?:\s?and\s?|\s?or\s?)\b)(?:#{QuotedFragment}|\S+)\s*)+)/o
    BOOLEAN_OPERATORS       = %w(and or).freeze

    attr_reader :blocks

    def initialize(tag_name, markup, options)
      super
      @blocks = []
      push_block('if', markup)
    end

    def nodelist
      @blocks.map(&:attachment)
    end

    def parse(tokens)
      while parse_body(@blocks.last.attachment, tokens)
      end
      @blocks.reverse_each do |block|
        block.attachment.remove_blank_strings if blank?
        block.attachment.freeze
      end
    end

    ELSE_TAG_NAMES = ['elsif', 'else'].freeze
    private_constant :ELSE_TAG_NAMES

    def unknown_tag(tag, markup, tokens)
      if ELSE_TAG_NAMES.include?(tag)
        push_block(tag, markup)
      else
        super
      end
    end

    def render_to_output_buffer(context, output)
      @blocks.each do |block|
        result = Liquid::Utils.to_liquid_value(
          block.evaluate(context)
        )

        if result
          return block.attachment.render_to_output_buffer(context, output)
        end
      end

      output
    end

    private

    def push_block(tag, markup)
      block = if tag == 'else'
        ElseCondition.new
      else
        parse_with_selected_parser(markup)
      end

      @blocks.push(block)
      block.attach(new_body)
    end

    def parse_expression(markup)
      Condition.parse_expression(parse_context, markup)
    end

    def lax_parse(markup)
      expressions = markup.scan(ExpressionsAndOperators)
      raise SyntaxError, options[:locale].t("errors.syntax.if") unless expressions.pop =~ Syntax

      condition = Condition.new(parse_expression(Regexp.last_match(1)), Regexp.last_match(2), parse_expression(Regexp.last_match(3)))

      until expressions.empty?
        operator = expressions.pop.to_s.strip

        raise SyntaxError, options[:locale].t("errors.syntax.if") unless expressions.pop.to_s =~ Syntax

        new_condition = Condition.new(parse_expression(Regexp.last_match(1)), Regexp.last_match(2), parse_expression(Regexp.last_match(3)))
        raise SyntaxError, options[:locale].t("errors.syntax.if") unless BOOLEAN_OPERATORS.include?(operator)
        new_condition.send(operator, condition)
        condition = new_condition
      end

      condition
    end

    def strict_parse(markup)
      p = Parser.new(markup)
      condition = parse_binary_comparisons(p)
      p.consume(:end_of_string)
      condition
    end

    def parse_binary_comparisons(p)
      condition = parse_comparison(p)
      first_condition = condition
      while (op = (p.id?('and') || p.id?('or')))
        child_condition = parse_comparison(p)
        condition.send(op, child_condition)
        condition = child_condition
      end
      first_condition
    end

    def parse_comparison(p)
      a = parse_expression(p.expression)
      if (op = p.consume?(:comparison))
        b = parse_expression(p.expression)
        Condition.new(a, op, b)
      else
        Condition.new(a)
      end
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        @node.blocks
      end
    end
  end

  Template.register_tag('if', If)
end
