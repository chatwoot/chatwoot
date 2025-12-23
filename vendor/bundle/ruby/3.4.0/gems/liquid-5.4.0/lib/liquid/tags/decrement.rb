# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category variable
  # @liquid_name decrement
  # @liquid_summary
  #   Creates a new variable, with a default value of -1, that's decreased by 1 with each subsequent call.
  # @liquid_description
  #   Variables that are declared with `decrement` are unique to the [layout](/themes/architecture/layouts), [template](/themes/architecture/templates),
  #   or [section](/themes/architecture/sections) file that they're created in. However, the variable is shared across
  #   [snippets](/themes/architecture#snippets) included in the file.
  #
  #   Similarly, variables that are created with `decrement` are independent from those created with [`assign`](/api/liquid/tags#assign)
  #   and [`capture`](/api/liquid/tags#capture). However, `decrement` and [`increment`](/api/liquid/tags#increment) share
  #   variables.
  # @liquid_syntax
  #   {% decrement variable_name %}
  # @liquid_syntax_keyword variable_name The name of the variable being decremented.
  class Decrement < Tag
    def initialize(tag_name, markup, options)
      super
      @variable = markup.strip
    end

    def render_to_output_buffer(context, output)
      value = context.environments.first[@variable] ||= 0
      value -= 1
      context.environments.first[@variable] = value
      output << value.to_s
      output
    end
  end

  Template.register_tag('decrement', Decrement)
end
