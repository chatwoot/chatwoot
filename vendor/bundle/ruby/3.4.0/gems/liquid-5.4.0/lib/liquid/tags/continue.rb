# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type tag
  # @liquid_category iteration
  # @liquid_name continue
  # @liquid_summary
  #   Causes a [`for` loop](/api/liquid/tags#for) to skip to the next iteration.
  # @liquid_syntax
  #   {% continue %}
  class Continue < Tag
    INTERRUPT = ContinueInterrupt.new.freeze

    def render_to_output_buffer(context, output)
      context.push_interrupt(INTERRUPT)
      output
    end
  end

  Template.register_tag('continue', Continue)
end
