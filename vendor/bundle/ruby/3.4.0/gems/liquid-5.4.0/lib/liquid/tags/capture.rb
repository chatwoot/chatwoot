# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category variable
  # @liquid_name capture
  # @liquid_summary
  #   Creates a new variable with a string value.
  # @liquid_description
  #   You can create complex strings with Liquid logic and variables.
  # @liquid_syntax
  #   {% capture variable %}
  #     value
  #   {% endcapture %}
  # @liquid_syntax_keyword variable The name of the variable being created.
  # @liquid_syntax_keyword value The value you want to assign to the variable.
  class Capture < Block
    Syntax = /(#{VariableSignature}+)/o

    def initialize(tag_name, markup, options)
      super
      if markup =~ Syntax
        @to = Regexp.last_match(1)
      else
        raise SyntaxError, options[:locale].t("errors.syntax.capture")
      end
    end

    def render_to_output_buffer(context, output)
      context.resource_limits.with_capture do
        capture_output = render(context)
        context.scopes.last[@to] = capture_output
      end
      output
    end

    def blank?
      true
    end
  end

  Template.register_tag('capture', Capture)
end
