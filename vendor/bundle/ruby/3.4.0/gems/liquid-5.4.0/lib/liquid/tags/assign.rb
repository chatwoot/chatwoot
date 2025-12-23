# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category variable
  # @liquid_name assign
  # @liquid_summary
  #   Creates a new variable.
  # @liquid_description
  #   You can create variables of any [basic type](/api/liquid/basics#types), [object](/api/liquid/objects), or object property.
  # @liquid_syntax
  #   {% assign variable_name = value %}
  # @liquid_syntax_keyword variable_name The name of the variable being created.
  # @liquid_syntax_keyword value The value you want to assign to the variable.
  class Assign < Tag
    Syntax = /(#{VariableSignature}+)\s*=\s*(.*)\s*/om

    # @api private
    def self.raise_syntax_error(parse_context)
      raise Liquid::SyntaxError, parse_context.locale.t('errors.syntax.assign')
    end

    attr_reader :to, :from

    def initialize(tag_name, markup, parse_context)
      super
      if markup =~ Syntax
        @to   = Regexp.last_match(1)
        @from = Variable.new(Regexp.last_match(2), parse_context)
      else
        self.class.raise_syntax_error(parse_context)
      end
    end

    def render_to_output_buffer(context, output)
      val = @from.render(context)
      context.scopes.last[@to] = val
      context.resource_limits.increment_assign_score(assign_score_of(val))
      output
    end

    def blank?
      true
    end

    private

    def assign_score_of(val)
      if val.instance_of?(String)
        val.bytesize
      elsif val.instance_of?(Array)
        sum = 1
        # Uses #each to avoid extra allocations.
        val.each { |child| sum += assign_score_of(child) }
        sum
      elsif val.instance_of?(Hash)
        sum = 1
        val.each do |key, entry_value|
          sum += assign_score_of(key)
          sum += assign_score_of(entry_value)
        end
        sum
      else
        1
      end
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        [@node.from]
      end
    end
  end

  Template.register_tag('assign', Assign)
end
