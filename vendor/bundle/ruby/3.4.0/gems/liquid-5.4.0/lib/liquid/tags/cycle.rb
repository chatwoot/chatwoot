# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category iteration
  # @liquid_name cycle
  # @liquid_summary
  #   Loops through a group of strings and outputs them one at a time for each iteration of a [`for` loop](/api/liquid/tags#for).
  # @liquid_description
  #   The `cycle` tag must be used inside a `for` loop.
  #
  #   > Tip:
  #   > Use the `cycle` tag to output text in a predictable pattern. For example, to apply odd/even classes to rows in a table.
  # @liquid_syntax
  #   {% cycle string, string, ... %}
  class Cycle < Tag
    SimpleSyntax = /\A#{QuotedFragment}+/o
    NamedSyntax  = /\A(#{QuotedFragment})\s*\:\s*(.*)/om

    attr_reader :variables

    def initialize(tag_name, markup, options)
      super
      case markup
      when NamedSyntax
        @variables = variables_from_string(Regexp.last_match(2))
        @name      = parse_expression(Regexp.last_match(1))
      when SimpleSyntax
        @variables = variables_from_string(markup)
        @name      = @variables.to_s
      else
        raise SyntaxError, options[:locale].t("errors.syntax.cycle")
      end
    end

    def render_to_output_buffer(context, output)
      context.registers[:cycle] ||= {}

      key       = context.evaluate(@name)
      iteration = context.registers[:cycle][key].to_i

      val = context.evaluate(@variables[iteration])

      if val.is_a?(Array)
        val = val.join
      elsif !val.is_a?(String)
        val = val.to_s
      end

      output << val

      iteration += 1
      iteration = 0 if iteration >= @variables.size

      context.registers[:cycle][key] = iteration
      output
    end

    private

    def variables_from_string(markup)
      markup.split(',').collect do |var|
        var =~ /\s*(#{QuotedFragment})\s*/o
        Regexp.last_match(1) ? parse_expression(Regexp.last_match(1)) : nil
      end.compact
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        Array(@node.variables)
      end
    end
  end

  Template.register_tag('cycle', Cycle)
end
