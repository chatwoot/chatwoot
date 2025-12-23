# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category syntax
  # @liquid_name echo
  # @liquid_summary
  #   Outputs an expression.
  # @liquid_description
  #   Using the `echo` tag is the same as wrapping an expression in curly brackets (`{{` and `}}`). However, unlike the curly
  #   bracket method, you can use the `echo` tag inside [`liquid` tags](/api/liquid/tags#liquid).
  #
  #   > Tip:
  #   > You can use [filters](/api/liquid/filters) on expressions inside `echo` tags.
  # @liquid_syntax
  #   {% liquid
  #     echo expression
  #   %}
  # @liquid_syntax_keyword expression The expression to be output.
  class Echo < Tag
    attr_reader :variable

    def initialize(tag_name, markup, parse_context)
      super
      @variable = Variable.new(markup, parse_context)
    end

    def render(context)
      @variable.render_to_output_buffer(context, +'')
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        [@node.variable]
      end
    end
  end

  Template.register_tag('echo', Echo)
end
