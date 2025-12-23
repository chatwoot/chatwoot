# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category theme
  # @liquid_name render
  # @liquid_summary
  #   Renders a [snippet](/themes/architecture#snippets) or [app block](/themes/architecture/sections/section-schema#render-app-blocks).
  # @liquid_description
  #   Inside snippets and app blocks, you can't directly access variables that are [created](/api/liquid/tags#variable-tags) outside
  #   of the snippet or app block. However, you can [specify variables as parameters](/api/liquid/tags#render-passing-variables-to-snippets)
  #   to pass outside variables to snippets.
  #
  #   While you can't directly access created variables, you can access global objects, as well as any objects that are
  #   directly accessible outside the snippet or app block. For example, a snippet or app block inside the [product template](/themes/architecture/templates/product)
  #   can access the [`product` object](/api/liquid/objects#product), and a snippet or app block inside a [section](/themes/architecture/sections)
  #   can access the [`section` object](/api/liquid/objects#section).
  #
  #   Outside a snippet or app block, you can't access variables created inside the snippet or app block.
  #
  #   > Note:
  #   > When you render a snippet using the `render` tag, you can't use the [`include` tag](/api/liquid/tags#include)
  #   > inside the snippet.
  # @liquid_syntax
  #   {% render 'filename' %}
  # @liquid_syntax_keyword filename The name of the snippet to render, without the `.liquid` extension.
  class Render < Tag
    FOR = 'for'
    SYNTAX = /(#{QuotedString}+)(\s+(with|#{FOR})\s+(#{QuotedFragment}+))?(\s+(?:as)\s+(#{VariableSegment}+))?/o

    disable_tags "include"

    attr_reader :template_name_expr, :variable_name_expr, :attributes

    def initialize(tag_name, markup, options)
      super

      raise SyntaxError, options[:locale].t("errors.syntax.render") unless markup =~ SYNTAX

      template_name = Regexp.last_match(1)
      with_or_for = Regexp.last_match(3)
      variable_name = Regexp.last_match(4)

      @alias_name = Regexp.last_match(6)
      @variable_name_expr = variable_name ? parse_expression(variable_name) : nil
      @template_name_expr = parse_expression(template_name)
      @for = (with_or_for == FOR)

      @attributes = {}
      markup.scan(TagAttributes) do |key, value|
        @attributes[key] = parse_expression(value)
      end
    end

    def render_to_output_buffer(context, output)
      render_tag(context, output)
    end

    def render_tag(context, output)
      # The expression should be a String literal, which parses to a String object
      template_name = @template_name_expr
      raise ::ArgumentError unless template_name.is_a?(String)

      partial = PartialCache.load(
        template_name,
        context: context,
        parse_context: parse_context
      )

      context_variable_name = @alias_name || template_name.split('/').last

      render_partial_func = ->(var, forloop) {
        inner_context               = context.new_isolated_subcontext
        inner_context.template_name = template_name
        inner_context.partial       = true
        inner_context['forloop']    = forloop if forloop

        @attributes.each do |key, value|
          inner_context[key] = context.evaluate(value)
        end
        inner_context[context_variable_name] = var unless var.nil?
        partial.render_to_output_buffer(inner_context, output)
        forloop&.send(:increment!)
      }

      variable = @variable_name_expr ? context.evaluate(@variable_name_expr) : nil
      if @for && variable.respond_to?(:each) && variable.respond_to?(:count)
        forloop = Liquid::ForloopDrop.new(template_name, variable.count, nil)
        variable.each { |var| render_partial_func.call(var, forloop) }
      else
        render_partial_func.call(variable, nil)
      end

      output
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        [
          @node.template_name_expr,
          @node.variable_name_expr,
        ] + @node.attributes.values
      end
    end
  end

  Template.register_tag('render', Render)
end
