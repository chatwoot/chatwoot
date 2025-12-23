# frozen_string_literal: true

module Liquid
  # Break tag to be used to break out of a for loop.
  #
  # == Basic Usage:
  #    {% for item in collection %}
  #      {% if item.condition %}
  #        {% break %}
  #      {% endif %}
  #    {% endfor %}
  #
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category iteration
  # @liquid_name break
  # @liquid_summary
  #   Stops a [`for` loop](/api/liquid/tags#for) from iterating.
  # @liquid_syntax
  #   {% break %}
  class Break < Tag
    INTERRUPT = BreakInterrupt.new.freeze

    def render_to_output_buffer(context, output)
      context.push_interrupt(INTERRUPT)
      output
    end
  end

  Template.register_tag('break', Break)
end
